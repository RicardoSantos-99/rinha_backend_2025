defmodule PaymentDispatcher.Application do
  use Application

  alias PaymentDispatcher.Server

  @impl true
  def start(_type, _args) do
    children = [
      {Bandit, plug: Server, port: "9999"}
    ]

    children = children ++ start_global_process_if_primary_app(Node.self())

    connect_to_cluster(:timer.minutes(1))

    opts = [strategy: :one_for_one, name: PaymentDispatcher.Supervisor]

    children
    |> List.flatten()
    |> Supervisor.start_link(opts)
  end

  defp start_global_process_if_primary_app(:api1@app1) do
    [
      PaymentDispatcher.StateManager,
      PaymentDispatcher.PaymentRouter
    ]
  end

  defp start_global_process_if_primary_app(_), do: []

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
        IO.inspect("Connected to cluster!!!")
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
end
