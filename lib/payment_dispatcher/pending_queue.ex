defmodule PaymentDispatcher.PendingQueue do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    :ok = init_index_counter()

    :ets.new(__MODULE__, [
      :ordered_set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, nil}
  end

  def init_index_counter() do
    :persistent_term.put({:index, __MODULE__}, :atomics.new(1, signed: false))
  end

  def get_next_index() do
    {:index, __MODULE__}
    |> :persistent_term.get()
    |> :atomics.add_get(1, 1)
  end

  def insert(payment) do
    true = :ets.insert(__MODULE__, {get_next_index(), payment})

    :ok
  end

  def insert(payment, index) do
    :ets.insert(__MODULE__, {index, payment})
  end

  def take_next() do
    case :ets.first(__MODULE__) do
      :"$end_of_table" ->
        :empty

      index ->
        case :ets.take(__MODULE__, index) do
          [] ->
            take_next()

          [{^index, payment}] ->
            {index, payment}
        end
    end
  end
end
