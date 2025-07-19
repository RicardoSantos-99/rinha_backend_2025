defmodule PaymentDispatcherWeb.PaymentsController do
  use PaymentDispatcherWeb, :controller

  alias PaymentDispatcher.PaymentManager
  alias PaymentDispatcher.StateManager

  def create(conn, _params) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)

    PaymentManager.process_payment(body)

    send_resp(conn, 201, "ok")
  end

  def summary(conn, _params) do
    %{"from" => from, "to" => to} = conn.query_params

    state = StateManager.get_state(from, to)

    conn
    |> put_status(:ok)
    |> json(state)
  end

  def purge_payments(conn, _params) do
    StateManager.purge_payments()

    conn
    |> put_status(:ok)
    |> json(%{message: "Payments purged"})
  end
end
