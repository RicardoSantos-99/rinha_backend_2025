defmodule PaymentDispatcher.Application do
  use Application

  alias PaymentDispatcher.Server

  @impl true
  def start(_type, _args) do
    children = [
      :poolboy.child_spec(:payment_manager_pool, poolboy_config(), []),
      PaymentDispatcher.StateManager,
      PaymentDispatcher.PaymentRouter,
      {Bandit, plug: Server, port: "9999"}
    ]

    connect_to_cluster(:timer.minutes(1))

    opts = [strategy: :one_for_one, name: PaymentDispatcher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp connect_to_cluster(timeout) do
    do_connect_to_cluster(timeout, System.monotonic_time(:second))
  end

  defp do_connect_to_cluster(timeout, start) do
    nodes = System.get_env("PEER_NODES")

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
      size: 25,
      max_overflow: 0
    ]
  end
end
