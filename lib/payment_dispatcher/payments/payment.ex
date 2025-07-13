defmodule PaymentDispatcher.Payments.Payment do
  alias PaymentDispatcher.Ports.PaymentProcessors

  def execute(amount, correlation_id, requested_at) do
    PaymentProcessors.process_payment(amount, correlation_id, requested_at)
    |> case do
      {:ok, %{"message" => "payment processed successfully"}} ->
        {:ok, :default}

      {:error, message} ->
        {:error, message}
    end
  end
end
