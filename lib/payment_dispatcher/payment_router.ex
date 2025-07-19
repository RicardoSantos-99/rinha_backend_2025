defmodule PaymentDispatcher.PaymentRouter do
  use GenServer

  alias PaymentDispatcher.Payments.Payment

  @default_fee 0.5
  @fallback_fee 0.15
  @latency_weight 0.0001
  @priority_threshold 1000

  @initial_state %{
    default: %{
      failing: false,
      min_response_time: 1
    },
    fallback: %{
      failing: false,
      min_response_time: 1
    }
  }

  def start_link(_state) do
    case GenServer.whereis({:global, __MODULE__}) do
      nil ->
        GenServer.start_link(__MODULE__, @initial_state, name: {:global, __MODULE__})

      pid ->
        {:ok, pid}
    end
  end

  def choose_psp(amount) do
    GenServer.call({:global, __MODULE__}, {:choose_psp, amount})
  end

  # GenServer callbacks
  def init(state) do
    Process.send_after(self(), :check_health, 5000)
    {:ok, state}
  end

  def handle_info(:check_health, state) do
    new_state =
      Payment.default_health_check()
      |> update_state(state, :default)
      |> then(&update_state(Payment.fallback_health_check(), &1, :fallback))

    Process.send_after(self(), :check_health, 5000)
    {:noreply, new_state}
  end

  def handle_call({:choose_psp, amount}, _from, %{default: default, fallback: fallback} = state) do
    chosen =
      cond do
        default.failing and fallback.failing ->
          :all_down

        default.failing and not fallback.failing ->
          if amount >= @priority_threshold, do: :requeue, else: :fallback

        not default.failing and fallback.failing ->
          :default

        not default.failing and not fallback.failing ->
          default_cost = @default_fee + default.min_response_time * @latency_weight
          fallback_cost = @fallback_fee + fallback.min_response_time * @latency_weight

          if default_cost <= fallback_cost, do: :default, else: :fallback
      end

    {:reply, chosen, state}
  end

  defp update_state(
         {:ok, %{"failing" => failing, "minResponseTime" => min_response_time}},
         state,
         psp
       ) do
    Map.update!(state, psp, fn client ->
      %{client | failing: failing, min_response_time: min_response_time}
    end)
  end

  defp update_state({:error, message}, state, _psp) do
    IO.inspect(message, label: "Health check failed")
    state
  end
end
