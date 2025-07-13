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

  if Application.compile_env(:payment_dispatcher, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: PaymentDispatcherWeb.Telemetry
    end
  end
end
