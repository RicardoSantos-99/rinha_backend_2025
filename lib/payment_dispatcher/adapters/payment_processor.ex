defmodule PaymentDispatcher.Adapters.PaymentProcessor do
  @behaviour PaymentDispatcher.Behaviours.PaymentBehaviour

  alias PaymentDispatcher.Behaviours.PaymentBehaviour

  @payment_url "/payments"
  @health_check_url "/payments/service-health"

  @impl PaymentBehaviour
  def process_payment(amount, correlation_id, requested_at) do
    get_url()
    |> Path.join(@payment_url)
    |> Tesla.post(body(amount, correlation_id, requested_at), headers())
    |> handle_response(@payment_url)
  end

  @impl PaymentBehaviour
  def health_check do
    get_url()
    |> Path.join(@health_check_url)
    |> Tesla.get()
    |> handle_response(@health_check_url)
  end

  defp handle_response({:ok, %Tesla.Env{body: body}}, endpoint) do
    body
    |> Jason.decode()
    |> case do
      {:ok, response} ->
        {:ok, response}

      {:error, reason} ->
        IO.inspect(reason)
        IO.inspect(body)
        IO.inspect(endpoint)
        {:error, "Failed to decode response: #{inspect(reason)}"}
    end
  end

  defp handle_response({:error, reason}, _endpoint) do
    {:error, reason}
  end

  defp body(amount, correlation_id, requested_at) do
    %{
      amount: amount,
      correlationId: correlation_id,
      requestedAt: requested_at
    }
    |> Jason.encode!()
  end

  defp headers do
    [headers: [{"content-type", "application/json"}]]
  end

  defp get_url do
    config(:payment_processor_url)
  end

  defp config(key) do
    Application.fetch_env!(:payment_dispatcher, key)
  end
end
