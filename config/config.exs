# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :payment_dispatcher,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :payment_dispatcher, PaymentDispatcherWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: PaymentDispatcherWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PaymentDispatcher.PubSub,
  live_view: [signing_salt: "nt0usVLw"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tesla, adapter: Tesla.Adapter.Hackney, disable_deprecated_builder_warning: true

# Configure payment processor adapter
config :payment_dispatcher,
  adapters: [
    payment_processor: PaymentDispatcher.Adapters.PaymentProcessor
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
