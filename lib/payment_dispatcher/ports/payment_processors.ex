defmodule PaymentDispatcher.Ports.PaymentProcessors do
  @doc """
  Processes a payment using the configured adapter.
  """
  def process_payment(url, amount, correlation_id, requested_at) do
    adapter().process_payment(url, amount, correlation_id, requested_at)
  end

  @doc """
  Performs a health check on the payment processor.
  """
  def health_check(url) do
    adapter().health_check(url)
  end

  defp adapter do
    :payment_dispatcher
    |> Application.fetch_env!(:adapters)
    |> Keyword.fetch!(:payment_processor)
  end
end
