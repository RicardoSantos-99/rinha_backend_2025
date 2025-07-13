import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :payment_dispatcher, PaymentDispatcherWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "gwsDll+2q8gtbuu2jdo4mXGu1BOYnRQ+07smejzeHXoh3/eIZoTX8Olz92c8r9HF",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
