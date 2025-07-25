defmodule PaymentDispatcher.Worker do
  use GenServer

  alias PaymentDispatcher.PendingQueue
  alias PaymentDispatcher.PaymentRouter
  alias PaymentDispatcher.Adapters.PaymentProcessor
  alias PaymentDispatcher.Storage

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(_) do
    Process.send_after(self(), :process_payment, 0)
    {:ok, nil}
  end

  def handle_info(:process_payment, state) do
    process_payment(current_provider())
    Process.send_after(self(), :process_payment, 0)

    {:noreply, state}
  end

  defp process_payment(:all_down), do: :ok

  defp process_payment(provider) do
    case PendingQueue.take_next() do
      {_index, payment} ->
        now = DateTime.utc_now() |> DateTime.truncate(:millisecond) |> DateTime.to_iso8601()

        payment = Map.merge(payment, %{provider: provider, requested_at: now})
        do_payment(payment)

      _ ->
        :noop
    end
  end

  defp do_payment(payment) do
    case PaymentProcessor.process_payment(payment) do
      :ok ->
        true = Storage.write(payment)
        :ok

      :error ->
        PendingQueue.insert(payment)
    end
  end

  defp current_provider do
    case :global.whereis_name(PaymentDispatcher.PaymentRouter) do
      :undefined ->
        :all_down

      pid when is_pid(pid) ->
        try do
          PaymentRouter.choose_psp()
        catch
          :exit, _ -> :all_down
        end
    end
  end
end
