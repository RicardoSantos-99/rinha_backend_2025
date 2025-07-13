defmodule PaymentDispatcher.Behaviours.PaymentBehaviour do
  @callback process_payment(
              amount :: float(),
              correlationId :: String.t(),
              requestedAt :: DateTime.t()
            ) :: {:ok, map()} | {:error, message :: String.t()}

  @callback health_check() ::
              {:ok,
               %{
                 failing: boolean(),
                 minResponseTime: integer()
               }}
              | {:error, message :: String.t()}
end
