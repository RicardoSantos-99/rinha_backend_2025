defmodule PaymentDispatcher.Storage do
  @state %{
    default: %{totalRequests: 0, totalAmount: 0},
    fallback: %{totalRequests: 0, totalAmount: 0}
  }

  def init() do
    :ets.new(__MODULE__, [
      :ordered_set,
      :public,
      :named_table,
      decentralized_counters: true,
      write_concurrency: true
    ])
  end

  def write(payment) do
    timestamp =
      payment.requested_at |> DateTime.from_iso8601() |> elem(1) |> DateTime.to_unix(:millisecond)

    :ets.insert(
      __MODULE__,
      {{timestamp, payment.correlation_id}, %{provider: payment.provider, amount: payment.amount}}
    )
  end

  def flush(), do: :ets.delete_all_objects(__MODULE__)

  def global_query(from, to) do
    all_nodes = Node.list([:this, :visible])

    {payments, fails} = :rpc.multicall(all_nodes, __MODULE__, :query_range, [from, to], :infinity)

    if fails != [] do
      IO.warn("Falha ao consultar nodes: #{inspect(fails)}")
    end

    payments
    |> aggregate_payment_from_nodes()
    |> format_result()
  end

  def query_range(from, to) do
    from = parse_ts(from)
    to = parse_ts(to)

    query = query(from, to)

    __MODULE__
    |> :ets.select(query)
    |> aggregate_result()
  end

  defp query(nil, nil) do
    [{{{:"$1", :"$2"}, :"$3"}, [], [:"$3"]}]
  end

  defp query(nil, to) do
    [{{{:"$1", :"$2"}, :"$3"}, [{:"=<", :"$1", to}], [:"$3"]}]
  end

  defp query(from, nil) do
    [{{{:"$1", :"$2"}, :"$3"}, [{:>=, :"$1", from}], [:"$3"]}]
  end

  defp query(from, to) do
    [{{{:"$1", :"$2"}, :"$3"}, [{:andalso, {:>=, :"$1", from}, {:"=<", :"$1", to}}], [:"$3"]}]
  end

  defp aggregate_result(payments) do
    Enum.reduce(payments, @state, fn payment, acc ->
      Map.update!(acc, payment.provider, &count_payment(&1, payment.amount))
    end)
  end

  defp format_result(data) do
    Enum.into(data, %{}, fn {key, %{totalRequests: req, totalAmount: amount}} ->
      rounded_amt = round_amount(amount)

      {key, %{totalRequests: req, totalAmount: rounded_amt}}
    end)
  end

  defp count_payment(acc, amount) do
    %{
      acc
      | totalRequests: acc.totalRequests + 1,
        totalAmount: round_amount(acc.totalAmount + amount)
    }
  end

  defp aggregate_payment_from_nodes(payments) do
    Enum.reduce(payments, %{}, fn node_result, acc ->
      Map.merge(acc, node_result, fn _provider, a, b ->
        %{
          totalRequests: a.totalRequests + b.totalRequests,
          totalAmount: a.totalAmount + b.totalAmount
        }
      end)
    end)
  end

  defp parse_ts(nil), do: nil

  defp parse_ts(iso_str) when is_binary(iso_str) do
    case DateTime.from_iso8601(iso_str) do
      {:ok, dt, _} -> DateTime.to_unix(dt, :millisecond)
      _ -> nil
    end
  end

  defp round_amount(amount) when is_float(amount), do: Float.round(amount, 2)
  defp round_amount(amount) when is_integer(amount), do: Float.round(amount * 1.0, 2)
end
