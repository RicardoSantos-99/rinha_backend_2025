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
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    PaymentManager.process_payment(body)

    send_resp(conn, 200, "")
  end

  get "/payments-summary" do
    conn = fetch_query_params(conn)

    state = StateManager.get_state(conn.query_params["from"], conn.query_params["to"])

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, JSON.encode!(state))
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
