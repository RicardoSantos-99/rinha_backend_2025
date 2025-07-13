defmodule PaymentDispatcher.Ports.PaymentProcessors do
  @doc """
  Processes a payment using the configured adapter.
  """
  def process_payment(amount, correlation_id, requested_at) do
    adapter().process_payment(amount, correlation_id, requested_at)
  end

  @doc """
  Performs a health check on the payment processor.
  """
  def health_check do
    adapter().health_check()
  end

  defp adapter do
    :payment_dispatcher
    |> Application.fetch_env!(:adapters)
    |> Keyword.fetch!(:payment_processor)
  end
end
