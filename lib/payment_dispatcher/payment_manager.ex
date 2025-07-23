defmodule PaymentDispatcher.PaymentManager do
  alias PaymentDispatcher.Payments.Payment
  alias PaymentDispatcher.Storage

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

      {:ok, provider} ->
        Storage.insert(%{
          id: correlation_id,
          executed_at: requested_at,
          provider: provider,
          amount: amount
        })

      _error ->
        :noop
    end
  end
end
