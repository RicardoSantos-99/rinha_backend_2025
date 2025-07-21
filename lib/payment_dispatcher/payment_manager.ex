defmodule PaymentDispatcher.PaymentManager do
  alias PaymentDispatcher.Payments.Payment
  alias PaymentDispatcher.StateManager

  def process_payment(params) do
    Task.start(fn ->
      %{"amount" => amount, "correlationId" => correlation_id} = JSON.decode!(params)
      do_process_payment(amount, correlation_id)
    end)
  end

  defp do_process_payment(amount, correlation_id) do
    requested_at = DateTime.utc_now()

    case Payment.execute_payment(amount, correlation_id, requested_at) do
      {:ok, :requeue} ->
        Task.start(fn ->
          Process.sleep(1000)
          do_process_payment(amount, correlation_id)
        end)

      {:ok, value} ->
        StateManager.update_state(value, amount, requested_at)

      _error ->
        :noop
    end
  end
end
