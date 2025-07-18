defmodule PaymentDispatcher.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PaymentDispatcherWeb.Telemetry,
      {DNSCluster,
       query: Application.get_env(:payment_dispatcher, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PaymentDispatcher.PubSub},
      # Start a worker by calling: PaymentDispatcher.Worker.start_link(arg)
      # {PaymentDispatcher.Worker, arg},
      # Start to serve requests, typically the last entry
      PaymentDispatcherWeb.Endpoint,
      :poolboy.child_spec(
        :payment_manager_pool,
        poolboy_config(),
        # argumentos passados para start_link/1 do GenServer
        []
      ),
      PaymentDispatcher.StateManager,
      PaymentDispatcher.PaymentRouter
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PaymentDispatcher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp poolboy_config do
    [
      name: {:local, :payment_manager_pool},
      worker_module: PaymentDispatcher.PaymentManager,
      size: 5,
      max_overflow: 0
    ]
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PaymentDispatcherWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
