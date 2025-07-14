defmodule PaymentDispatcher.Payments.Payment do
  alias PaymentDispatcher.Ports.PaymentProcessors
  alias PaymentDispatcher.PaymentRouter

  def execute_payment(amount, correlation_id, requested_at) do
    psp = get_psp_url()

    do_execute_payment(psp, amount, correlation_id, requested_at)
  end

  defp do_execute_payment(:all_down, _amount, _correlation_id, _requested_at) do
    {:ok, :requeue}
  end

  defp do_execute_payment({psp, url}, amount, correlation_id, requested_at) do
    url
    |> PaymentProcessors.process_payment(amount, correlation_id, requested_at)
    |> case do
      {:ok, %{"message" => "payment processed successfully"}} ->
        {:ok, psp}

      _error ->
        {other_psp, other_url} = other_psp_url(psp)

        other_url
        |> PaymentProcessors.process_payment(amount, correlation_id, requested_at)
        |> case do
          {:ok, %{"message" => "payment processed successfully"}} ->
            {:ok, other_psp}

          _error ->
            {:error, "payment failed"}
        end
    end
  end

  def default_health_check do
    PaymentProcessors.health_check(get_default_url())
  end

  def fallback_health_check do
    PaymentProcessors.health_check(get_fallback_url())
  end

  defp get_psp_url do
    case PaymentRouter.choose_psp() do
      :default -> {:default, get_default_url()}
      :fallback -> {:fallback, get_fallback_url()}
      :all_down -> :all_down
    end
  end

  defp other_psp_url(:default), do: {:fallback, get_fallback_url()}
  defp other_psp_url(:fallback), do: {:default, get_default_url()}

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
