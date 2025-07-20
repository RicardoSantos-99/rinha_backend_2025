defmodule PaymentDispatcher.Payments.Payment do
  alias PaymentDispatcher.Adapters.PaymentProcessor
  alias PaymentDispatcher.PaymentRouter

  def execute_payment(amount, correlation_id, requested_at) do
    psp = get_psp_url(amount)

    do_execute_payment(psp, amount, correlation_id, requested_at)
  end

  defp do_execute_payment(:all_down, _amount, _correlation_id, _requested_at) do
    {:ok, :requeue}
  end

  defp do_execute_payment({psp, url}, amount, correlation_id, requested_at) do
    case PaymentProcessor.process_payment(url, amount, correlation_id, requested_at) do
      :ok -> {:ok, psp}
      error -> error
    end
  end

  def default_health_check do
    PaymentProcessor.available?(get_default_url())
  end

  def fallback_health_check do
    PaymentProcessor.available?(get_fallback_url())
  end

  defp get_psp_url(amount) do
    case PaymentRouter.choose_psp(amount) do
      :default -> {:default, get_default_url()}
      :fallback -> {:fallback, get_fallback_url()}
      :requeue -> :all_down
      :all_down -> :all_down
    end
  end

  defp get_default_url do
    config(:processor_default_url)
  end

  defp get_fallback_url do
    config(:processor_fallback_url)
  end

  defp config(key) do
    Application.fetch_env!(:payment_dispatcher, key)
  end
end
