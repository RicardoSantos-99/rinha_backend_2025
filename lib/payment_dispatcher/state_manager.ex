defmodule PaymentDispatcher.StateManager do
  use GenServer

  @initial_state %{
    default: [],
    fallback: []
  }

  def start_link(_state) do
    GenServer.start_link(__MODULE__, @initial_state, name: __MODULE__)
  end

  def update_state(client, amount, date) do
    GenServer.cast(__MODULE__, {:update_state, client, amount, date})
  end

  def get_state(from, to) do
    GenServer.call(__MODULE__, {:get_state, from, to}, :infinity)
  end

  def purge_payments do
    GenServer.call(__MODULE__, :purge_payments)
  end

  # GenServer callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_cast({:update_state, service, amount, date}, state) do
    new_state =
      Map.update!(state, service, fn service ->
        [%{amount: amount, date: date} | service]
      end)

    {:noreply, new_state}
  end

  def handle_call({:get_state, from, to}, _from, state) do
    {:ok, from, _} = DateTime.from_iso8601(from)
    {:ok, to, _} = DateTime.from_iso8601(to)

    res = %{
      default: sum_in_interval(state.default, from, to),
      fallback: sum_in_interval(state.fallback, from, to)
    }

    {:reply, res, state}
  end

  def handle_call(:purge_payments, _from, _state) do
    {:reply, :ok, @initial_state}
  end

  defp sum_in_interval(service, from, to) do
    Enum.reduce(service, %{totalRequests: 0, totalAmount: 0}, fn elem, acc ->
      if DateTime.after?(elem.date, from) and DateTime.before?(elem.date, to) do
        %{acc | totalRequests: acc.totalRequests + 1, totalAmount: acc.totalAmount + elem.amount}
      else
        acc
      end
    end)
  end
end
