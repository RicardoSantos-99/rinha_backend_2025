import Config

config :payment_dispatcher,
  processor_default_url: System.get_env("PROCESSOR_DEFAULT_URL") || "http://localhost:8001",
  processor_fallback_url: System.get_env("PROCESSOR_FALLBACK_URL") || "http://localhost:8002"
