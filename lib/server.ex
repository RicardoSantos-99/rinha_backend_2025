defmodule PaymentDispatcher.Server do
  use Plug.Router

  require Logger

  alias PaymentDispatcher.PendingQueue
  alias PaymentDispatcher.Storage

  plug(:match)
  plug(:dispatch)

  post "/payments" do
    {:ok, body, _} = read_body(conn)
    PendingQueue.insert(body)

    send_resp(conn, 200, "")
  end

  get "/payments-summary" do
    Process.flag(:priority, :max)

    conn = fetch_query_params(conn)
    state = Storage.global_query(conn.query_params["from"], conn.query_params["to"])

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, JSON.encode!(state))
  end

  post "/purge-payments" do
    start = System.monotonic_time()

    Storage.flush()

    log_duration("/purge-payments", start)
    send_resp(conn, 200, "")
  end

  get "/health" do
    send_resp(conn, 200, "")
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  defp log_duration(endpoint, start_time) do
    elapsed_us = System.monotonic_time() - start_time
    elapsed_ms = System.convert_time_unit(elapsed_us, :native, :millisecond)

    if elapsed_ms > 1 do
      Logger.warning("[#{endpoint}] took #{elapsed_ms}ms")
    end
  end
end
