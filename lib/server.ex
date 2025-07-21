defmodule PaymentDispatcher.Server do
  use Plug.Router

  alias PaymentDispatcher.PaymentManager
  alias PaymentDispatcher.StateManager

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:urlencoded],
    pass: ["*/*"]
  )

  plug(:dispatch)

  post "/payments" do
    start = System.monotonic_time(:microsecond)

    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    PaymentManager.process_payment(body)

    duration = System.monotonic_time(:microsecond) - start

    # 5ms em microssegundos
    if duration > 3_000 do
      IO.inspect("[WARN] /payments demorou #{duration}µs")
    end

    send_resp(conn, 200, "")
  end

  get "/payments-summary" do
    start = System.monotonic_time(:microsecond)

    conn = fetch_query_params(conn)
    # _state = StateManager.get_state(conn.query_params["from"], conn.query_params["to"])

    duration = System.monotonic_time(:microsecond) - start

    if duration > 3_000 do
      IO.inspect("[WARN] /payments-summary demorou #{duration}µs")
    end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      200,
      JSON.encode!(%{
        default: %{totalRequests: 1, totalAmount: 10},
        fallback: %{totalRequests: 1, totalAmount: 10}
      })
    )
  end

  post "/purge-payments" do
    StateManager.purge_payments()

    send_resp(conn, 200, "")
  end

  get "/health" do
    send_resp(conn, 200, "")
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
