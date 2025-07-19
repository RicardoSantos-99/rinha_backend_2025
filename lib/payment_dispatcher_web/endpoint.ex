defmodule PaymentDispatcherWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :payment_dispatcher

  plug Plug.Parsers,
    parsers: [:urlencoded],
    pass: ["*/*"]

  plug PaymentDispatcherWeb.Router
end
