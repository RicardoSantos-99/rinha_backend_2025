defmodule PaymentDispatcher.Behaviours.PaymentBehaviour do
  @callback process_payment(
              url :: String.t(),
              amount :: float(),
              correlationId :: String.t(),
              requestedAt :: DateTime.t()
            ) :: {:ok, map()} | {:error, message :: String.t()}

  @callback health_check(url :: String.t()) ::
              {:ok,
               %{
                 failing: boolean(),
                 minResponseTime: integer()
               }}
              | {:error, message :: String.t()}
end
