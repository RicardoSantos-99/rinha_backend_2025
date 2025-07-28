defmodule PaymentDispatcher.Warmup do
  @base_url "http://localhost:9999"
  @headers [{~c"Content-Type", ~c"application/json"}]

  def run(times \\ 5) when is_integer(times) and times > 0 do
    ensure_httpc_started()

    Enum.each(1..times, fn i ->
      post_payment(i)
      get_summary()
    end)

    purge_payments()
    IO.puts("finish warmup")
  end

  defp ensure_httpc_started do
    :inets.start()
    :ssl.start()
    :ok
  end

  defp post_payment(index) do
    payment = %{
      "amount" => Enum.random(100..1_000) / 100,
      "correlationId" => "warmup-#{index}-#{:erlang.unique_integer([:monotonic])}",
      "requestedAt" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "provider" => if(rem(index, 2) == 0, do: "default", else: "fallback")
    }

    body = JSON.encode!(payment) |> to_charlist()
    url = to_charlist(@base_url <> "/payments")

    :httpc.request(
      :post,
      {url, @headers, ~c"application/json", body},
      [],
      []
    )
    |> ignore_response()
  end

  defp get_summary do
    url = to_charlist(@base_url <> "/payments-summary?from=&to=")

    :get
    |> :httpc.request({url, []}, [], [])
    |> ignore_response()
  end

  defp purge_payments do
    url = to_charlist(@base_url <> "/purge-payments")

    :httpc.request(
      :post,
      {url, [], ~c"application/json", ~c""},
      [],
      []
    )
    |> ignore_response()
  end

  defp ignore_response({:ok, _}), do: :ok
  defp ignore_response(_), do: :error
end
