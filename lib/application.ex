defmodule PaymentDispatcher.Application do
  use Application

  alias PaymentDispatcher.Server
  alias PaymentDispatcher.Storage
  alias PaymentDispatcher.PendingQueue
  alias PaymentDispatcher.Worker
  alias PaymentDispatcher.PaymentRouter

  @shards 10

  @impl true
  def start(_type, _args) do
    connect_to_cluster(:timer.minutes(1))
    Process.flag(:fullsweep_after, 1_000_000_000)

    PendingQueue.init_all()
    Storage.init()

    children = [
      start_global_process_if_primary_app(Node.self()),
      workers(),
      {
        Bandit,
        plug: Server, scheme: :http, port: 9999, thousand_island_options: [num_acceptors: 35]
      }
    ]

    Enum.each(:code.all_loaded(), fn {mod, _} -> :code.ensure_loaded(mod) end)

    opts = [strategy: :one_for_one, name: PaymentDispatcher.Supervisor]

    {:ok, sup} =
      children
      |> List.flatten()
      |> Supervisor.start_link(opts)

    PaymentDispatcher.Warmup.run(40)
    {:ok, sup}
  end

  defp start_global_process_if_primary_app(:api1@app1), do: [PaymentRouter]
  defp start_global_process_if_primary_app(:nonode@nohost), do: [PaymentRouter]
  defp start_global_process_if_primary_app(_), do: []

  defp workers() do
    for shard <- 1..@shards do
      %{
        id: {:worker, shard},
        start: {Worker, :start_link, [shard]}
      }
    end
  end

  defp connect_to_cluster(timeout) do
    do_connect_to_cluster(timeout, System.monotonic_time(:second))
  end

  defp do_connect_to_cluster(timeout, start) do
    case System.get_env("PEER_NODES") do
      nil ->
        :ok

      nodes ->
        success =
          nodes
          |> String.split(",")
          |> Enum.reject(&(&1 == ""))
          |> Enum.map(&String.to_atom/1)
          |> Enum.all?(&Node.connect/1)

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
