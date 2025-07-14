defmodule PaymentDispatcher.PaymentManager do
  use GenServer

  alias PaymentDispatcher.Payments.Payment
  alias PaymentDispatcher.StateManager

  def start_link(_state) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def process_payment(amount, correlation_id) do
    GenServer.cast(__MODULE__, {:process_payment, amount, correlation_id})
  end

  # GenServer callbacks

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:process_payment, amount, correlation_id}, state) do
    requested_at = DateTime.utc_now()

    amount
    |> Payment.execute_payment(correlation_id, requested_at)
    |> case do
      {:ok, :requeue} ->
        Process.send_after(self(), {:process_payment, amount, correlation_id}, 1000)
        {:noreply, state}

      {:ok, value} ->
        {:noreply, StateManager.update_state(value, amount)}

      {:error, message} ->
        IO.inspect(inspect(message))
        {:noreply, state}
    end
  end
end
