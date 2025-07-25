defmodule PaymentDispatcher.Adapters.PaymentProcessor do
  def process_payment(%{
        amount: amount,
        correlation_id: correlation_id,
        requested_at: requested_at,
        provider: provider
      }) do
    body = body(amount, correlation_id, requested_at)

    case :httpc.request(
           :post,
           {~c"#{get_url(provider)}/payments", [], ~c"application/json", body},
           [],
           []
         ) do
      {:ok, {{_httpv, 200, _status_msg}, _headers, _charlist_body}} ->
        :ok

      _err ->
        :error
    end
  end

  def available?(provider) do
    case :httpc.request(:get, {~c"#{get_url(provider)}/payments/service-health", []}, [], []) do
      {:ok, {{_httpv, 200, _status_msg}, _headers, charlist_body}} ->
        case JSON.decode(to_string(charlist_body)) do
          {:ok, %{"failing" => failing?}} -> failing?
          _err -> true
        end

      _e ->
        true
    end
  end

  defp body(amount, correlation_id, requested_at) do
    %{
      "correlationId" => correlation_id,
      "amount" => amount,
      "requestedAt" => requested_at
    }
    |> JSON.encode!()
    |> to_charlist()
  end

  defp get_url(:default) do
    config(:processor_default_url)
  end

  defp get_url(:fallback) do
    config(:processor_fallback_url)
  end

  defp config(key) do
    Application.fetch_env!(:payment_dispatcher, key)
  end
end
