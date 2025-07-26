defmodule PaymentDispatcher.PendingQueue do
  @shards 10

  def init_all() do
    :ok = init_index_counter()

    for i <- 1..@shards do
      :ets.new(table_name(i), [
        :ordered_set,
        :public,
        :named_table,
        read_concurrency: true,
        write_concurrency: true
      ])
    end
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
    idx = get_next_index()
    shard = rem(idx, @shards) + 1
    :ets.insert(table_name(shard), {idx, payment})
    :ok
  end

  def insert(payment, index) do
    shard = rem(index, @shards) + 1
    :ets.insert(table_name(shard), {index, payment})
  end

  def take_next(shard) do
    table = table_name(shard)

    case :ets.first(table) do
      :"$end_of_table" ->
        :empty

      index ->
        case :ets.take(table, index) do
          [] -> take_next(shard)
          [{^index, payment}] -> {index, payment}
        end
    end
  end

  defp table_name(i), do: :"pending_queue_#{i}"
end
