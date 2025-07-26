defmodule ServerTest do
  use ExUnit.Case

  alias PaymentDispatcher.Storage

  test "simple ets match all" do
    [
      %{
        amount: 10.1,
        correlation_id: "1",
        provider: :default,
        requested_at: "2025-07-16T01:46:00.000000Z"
      },
      %{
        amount: 20.2,
        correlation_id: "2",
        provider: :default,
        requested_at: "2025-07-16T01:47:00.000000Z"
      },
      %{
        amount: 30.3,
        correlation_id: "3",
        provider: :default,
        requested_at: "2025-07-16T01:48:00.000000Z"
      },
      %{
        amount: 40.4,
        correlation_id: "4",
        provider: :fallback,
        requested_at: "2025-07-16T01:49:00.000000Z"
      },
      %{
        amount: 50.5,
        correlation_id: "5",
        provider: :fallback,
        requested_at: "2025-07-16T01:50:00.000000Z"
      }
    ]
    |> Enum.each(fn p -> Storage.write(p) end)

    assert %{
             default: %{
               totalRequests: 3,
               totalAmount: 60.6
             },
             fallback: %{
               totalRequests: 2,
               totalAmount: 90.9
             }
           } = Storage.query_range(nil, nil)
  end

  test "ets match time window" do
    {:ok, first_ts, 0} = DateTime.from_iso8601("2025-07-16T01:46:00.000000Z")
    base_amount = 10.0

    all_payments =
      Enum.map(0..1000, fn i ->
        %{
          amount: base_amount + i / 10,
          correlation_id: "#{i}",
          provider: if(rem(i, 2) == 0, do: :default, else: :fallback),
          requested_at: DateTime.add(first_ts, i, :minute) |> DateTime.to_iso8601()
        }
      end)

    Enum.each(all_payments, fn p -> Storage.write(p) end)

    :timer.tc(fn ->
      Storage.query_range(
        "2025-07-16T01:47:00.000000Z",
        "2025-07-16T01:50:00.000000Z"
      )
    end)

    Storage.flush()

    all_payments =
      Enum.map(0..1000, fn i ->
        %{
          amount: base_amount + i / 10,
          correlation_id: "#{i}",
          provider: if(rem(i, 2) == 0, do: :default, else: :fallback),
          requested_at: DateTime.add(first_ts, i, :minute) |> DateTime.to_iso8601()
        }
      end)

    Enum.each(all_payments, fn p -> Storage.write(p) end)

    assert %{
             default: %{
               totalRequests: 2,
               totalAmount: 20.6
             },
             fallback: %{
               totalRequests: 2,
               totalAmount: 20.4
             }
           } =
             Storage.query_range(
               "2025-07-16T01:47:00.000000Z",
               "2025-07-16T01:50:00.000000Z"
             )

    Storage.flush()
  end

  test "ets match from or to nil" do
    [
      %{
        amount: 10.1,
        correlation_id: "1",
        provider: :default,
        requested_at: "2025-07-16T01:46:00.000000Z"
      },
      %{
        amount: 20.2,
        correlation_id: "2",
        provider: :default,
        requested_at: "2025-07-16T01:47:00.000000Z"
      },
      %{
        amount: 30.3,
        correlation_id: "3",
        provider: :default,
        requested_at: "2025-07-16T01:48:00.000000Z"
      },
      %{
        amount: 40.4,
        correlation_id: "4",
        provider: :fallback,
        requested_at: "2025-07-16T01:49:00.000000Z"
      },
      %{
        amount: 50.5,
        correlation_id: "5",
        provider: :fallback,
        requested_at: "2025-07-16T01:50:00.000000Z"
      }
    ]
    |> Enum.each(fn p -> Storage.write(p) end)

    assert %{
             default: %{
               totalRequests: 2,
               totalAmount: 50.5
             },
             fallback: %{
               totalRequests: 2,
               totalAmount: 90.9
             }
           } = Storage.query_range("2025-07-16T01:47:00.000000Z", nil)

    assert %{
             default: %{
               totalRequests: 3,
               totalAmount: 60.6
             },
             fallback: %{
               totalRequests: 1,
               totalAmount: 40.4
             }
           } = Storage.query_range(nil, "2025-07-16T01:49:00.000000Z")

    Storage.flush()
  end
end
