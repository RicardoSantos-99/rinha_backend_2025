defmodule BEAMMonitor do
  def start_link(_) do
    Task.start_link(fn -> loop() end)
  end

  defp loop do
    total = :erlang.statistics(:run_queue)
    if total > 1, do: IO.puts("RUN QUEUE ALERT: #{total}")
    Process.sleep(100)
    loop()
  end
end
