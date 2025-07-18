defmodule PaymentDispatcher.PaymentRouter do
  use GenServer

  alias PaymentDispatcher.Payments.Payment

  @default_fee 0.5
  @fallback_fee 0.15
  @latency_weight 0.0001

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
    GenServer.start_link(__MODULE__, @initial_state, name: __MODULE__)
  end

  def choose_psp do
    GenServer.call(__MODULE__, :choose_psp)
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
          default_cost =
            @default_fee + default.min_response_time * @latency_weight

          fallback_cost =
            @fallback_fee + fallback.min_response_time * @latency_weight

          if default_cost <= fallback_cost do
            :default
          else
            :fallback
          end
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

  defp update_state(
         {:error, message},
         state,
         _psp
       ) do
    IO.inspect(message)
    state
  end
end
