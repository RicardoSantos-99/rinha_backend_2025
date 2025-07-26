defmodule PaymentDispatcher.QueueLatencyPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    client_start =
      case get_req_header(conn, "x-client-start") do
        [val | _] ->
          case Integer.parse(val) do
            {ts, _} -> ts
            _ -> nil
          end

        _ ->
          nil
      end

    if client_start do
      now_ms = System.system_time(:millisecond)
      queue_latency = now_ms - client_start

      if queue_latency > 5 do
        IO.inspect(queue_latency, label: "Queue Latency")
      end

      conn
      |> assign(:queue_latency, queue_latency)
      |> put_resp_header("x-queue-latency-ms", Integer.to_string(queue_latency))
    else
      conn
    end
  end
end
