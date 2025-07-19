defmodule PaymentDispatcherWeb.Router do
  use PaymentDispatcherWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", PaymentDispatcherWeb do
    pipe_through :api
  end

  scope "/", PaymentDispatcherWeb do
    post "/payments", PaymentsController, :create
    get "/payments-summary", PaymentsController, :summary
    post "/purge-payments", PaymentsController, :purge_payments
  end
end
