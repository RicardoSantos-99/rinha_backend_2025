defmodule PaymentDispatcher.StateManager do
  use GenServer

  @initial_state %{
    default: %{totalRequests: 0, totalAmount: 0},
    fallback: %{totalRequests: 0, totalAmount: 0}
  }

  def start_link(_state) do
    GenServer.start_link(__MODULE__, @initial_state, name: __MODULE__)
  end

  def update_state(client, amount) do
    GenServer.cast(__MODULE__, {:update_state, client, amount})
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state, :infinity)
  end

  def purge_payments do
    GenServer.call(__MODULE__, :purge_payments)
  end

  # GenServer callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_cast({:update_state, client, amount}, state) do
    new_state =
      Map.update!(state, client, fn client ->
        %{
          client
          | totalAmount: client.totalAmount + amount,
            totalRequests: client.totalRequests + 1
        }
      end)

    {:noreply, new_state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:purge_payments, _from, _state) do
    {:reply, :ok, @initial_state}
  end
end
