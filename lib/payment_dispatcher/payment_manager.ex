defmodule PaymentDispatcher.PaymentManager do
  use GenServer

  alias PaymentDispatcher.Payments.Payment
  alias PaymentDispatcher.StateManager

  def start_link(_state) do
    GenServer.start_link(__MODULE__, %{})
  end

  def process_payment(params) do
    :poolboy.transaction(
      :payment_manager_pool,
      fn pid ->
        GenServer.cast(pid, {:process_payment, params})
      end
    )
  end

  defp process_payment_with_delay(amount, correlation_id, delay) do
    :poolboy.transaction(
      :payment_manager_pool,
      fn pid ->
        Process.send_after(pid, {:process_payment, amount, correlation_id}, delay)
      end
    )
  end

  # GenServer callbacks

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:process_payment, params}, state) do
    %{"amount" => amount, "correlationId" => correlation_id} = Jason.decode!(params)
    do_process_payment(amount, correlation_id, state)
  end

  def handle_cast({:process_payment, amount, correlation_id}, state) do
    do_process_payment(amount, correlation_id, state)
  end

  def handle_info({:process_payment, amount, correlation_id}, state) do
    do_process_payment(amount, correlation_id, state)
  end

  defp do_process_payment(amount, correlation_id, state) do
    requested_at = DateTime.utc_now()

    case Payment.execute_payment(amount, correlation_id, requested_at) do
      {:ok, :requeue} ->
        process_payment_with_delay(amount, correlation_id, 1000)
        {:noreply, state}

      {:ok, value} ->
        {:noreply, StateManager.update_state(value, amount, requested_at)}

      {:error, message} ->
        IO.inspect(inspect(message))
        {:noreply, state}
    end
  end
end
