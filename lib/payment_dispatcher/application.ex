defmodule PaymentDispatcher.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PaymentDispatcherWeb.Telemetry,
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

    connect_to_cluster(:timer.minutes(1))

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PaymentDispatcher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp connect_to_cluster(timeout) do
    do_connect_to_cluster(timeout, System.monotonic_time(:second))
  end

  defp do_connect_to_cluster(timeout, start) do
    nodes = System.get_env("PEER_NODES")

    # {:ok, hostname} = :inet.gethostname()

    if nodes != nil do
      success =
        nodes
        |> String.split(",")
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(&String.to_atom/1)
        |> Enum.all?(&Node.connect(&1))

      if success do
        IO.inspect("Connected to cluster!")
        :ok
      else
        if System.monotonic_time(:second) - start > timeout do
          raise "TIMEOUT! Could not connect to cluster!"
        else
          Process.sleep(:timer.seconds(1))
          do_connect_to_cluster(timeout, start)
        end
      end
    end
  end

  defp poolboy_config do
    [
      name: {:local, :payment_manager_pool},
      worker_module: PaymentDispatcher.PaymentManager,
      size: 3,
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
