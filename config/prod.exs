import Config

# Do not print debug messages in production
config :logger, backends: []

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
