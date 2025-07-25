defmodule PaymentDispatcher.PaymentRouter do
  use GenServer

  alias PaymentDispatcher.Adapters.PaymentProcessor

  @initial_state %{default: %{failing: false}, fallback: %{failing: false}}

  def start_link(_state) do
    case GenServer.whereis({:global, __MODULE__}) do
      nil -> GenServer.start_link(__MODULE__, @initial_state, name: {:global, __MODULE__})
      pid -> {:ok, pid}
    end
  end

  def choose_psp() do
    GenServer.call({:global, __MODULE__}, :choose_psp)
  end

  # GenServer callbacks
  def init(state) do
    Process.send_after(self(), :check_health, 5000)
    {:ok, state}
  end

  def handle_info(:check_health, state) do
    new_state =
      :default
      |> PaymentProcessor.available?()
      |> update_state(state, :default)
      |> then(&update_state(PaymentProcessor.available?(:fallback), &1, :fallback))

    Process.send_after(self(), :check_health, 5000)
    {:noreply, new_state}
  end

  def handle_call(:choose_psp, _from, %{default: default, fallback: fallback} = state) do
    chosen =
      cond do
        default.failing and fallback.failing ->
          :all_down

        default.failing and not fallback.failing ->
          :fallback

        not default.failing and fallback.failing ->
          :default

        not default.failing and not fallback.failing ->
          :default
      end

    {:reply, chosen, state}
  end

  defp update_state(failing, state, psp) do
    Map.update!(state, psp, fn client ->
      %{client | failing: failing}
    end)
  end
end
