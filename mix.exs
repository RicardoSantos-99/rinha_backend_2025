defmodule PaymentDispatcher.MixProject do
  use Mix.Project

  def project do
    [
      app: :payment_dispatcher,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {PaymentDispatcher.Application, []},
      extra_applications: [:logger, :inets, :observer, :wx]
    ]
  end

  defp deps do
    [
      {:bandit, "~> 1.7"},
      {:plug, "~> 1.18"}
    ]
  end
end
