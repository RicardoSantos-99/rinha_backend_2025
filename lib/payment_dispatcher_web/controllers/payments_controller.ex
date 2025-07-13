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

  def summary(conn, _params) do
    # %{"from" => "2025-07-13T18:30:06.678Z", "to" => "2025-07-13T18:30:16.578Z"}

    state = StateManager.get_state()

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
