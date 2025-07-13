defmodule PaymentDispatcher.Payments.Payment do
  alias PaymentDispatcher.Ports.PaymentProcessors

  def execute(amount, correlation_id, requested_at) do
    get_default_url()
    |> PaymentProcessors.process_payment(amount, correlation_id, requested_at)
    |> case do
      {:ok, %{"message" => "payment processed successfully"}} ->
        {:ok, :default}

      {:error, message} ->
        {:error, message}
    end
  end

  def get_default_url do
    config(:processor_default_url)
  end

  def get_fallback_url do
    config(:processor_fallback_url)
  end

  defp config(key) do
    :payment_dispatcher
    |> Application.fetch_env!(key)
  end
end
