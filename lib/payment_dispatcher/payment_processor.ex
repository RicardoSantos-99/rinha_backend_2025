defmodule PaymentDispatcher.Adapters.PaymentProcessor do
  def process_payment(url, amount, correlation_id, requested_at) do
    body = body(amount, correlation_id, requested_at)

    case :httpc.request(:post, {~c"#{url}/payments", [], ~c"application/json", body}, [], []) do
      {:ok, {{_httpv, 200, _status_msg}, _headers, _charlist_body}} ->
        :ok

      _err ->
        :error
    end
  end

  def available?(url) do
    case :httpc.request(:get, {~c"#{url}/payments/service-health", []}, [], []) do
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
end
