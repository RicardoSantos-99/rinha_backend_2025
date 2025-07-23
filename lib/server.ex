defmodule PaymentDispatcher.Server do
  use Plug.Router

  alias PaymentDispatcher.PaymentManager
  alias PaymentDispatcher.Storage

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

    if duration > 300 do
      IO.inspect("[WARN] /payments demorou #{duration}")
    end

    send_resp(conn, 200, "")
  end

  get "/payments-summary" do
    start = System.monotonic_time(:microsecond)

    conn = fetch_query_params(conn)
    state = Storage.global_query(conn.query_params["from"], conn.query_params["to"])

    duration = System.monotonic_time(:microsecond) - start

    if duration > 300 do
      IO.inspect("[WARN] /payments-summary demorou #{duration}")
    end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, JSON.encode!(state))
  end

  post "/purge-payments" do
    Storage.flush()

    send_resp(conn, 200, "")
  end

  get "/health" do
    send_resp(conn, 200, "")
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
