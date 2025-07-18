defmodule PaymentDispatcherWeb.PaymentsController do
  use PaymentDispatcherWeb, :controller

  alias PaymentDispatcher.PaymentManager
  alias PaymentDispatcher.StateManager

  def create(conn, %{"amount" => amount, "correlationId" => correlation_id}) do
    PaymentManager.process_payment(amount, correlation_id)

    conn
    |> put_status(:created)
    |> json(%{message: "Payment created"})
  end

  def summary(conn, %{"from" => from, "to" => to}) do
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
