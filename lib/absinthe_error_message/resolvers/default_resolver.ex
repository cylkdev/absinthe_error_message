defmodule AbsintheErrorMessage.Resolvers.DefaultResolver do
  @moduledoc """
  This module is a basic resolver that converts error messages into top level error message structs.
  """
  alias AbsintheErrorMessage.TopLevelMessage

  @type error_message :: AbsintheErrorMessage.error_message()
  @type resolution :: Absinthe.Resolution.t()
  @type top_level_message :: AbsintheErrorMessage.TopLevelMessage.t()

  @service_unavailable_message "service unavailable, please try again in a few minutes"

  @behaviour AbsintheErrorMessage.Adapter.Resolver

  @impl AbsintheErrorMessage.Adapter.Resolver
  @doc """
  Converts an error message map into a `AbsintheErrorMessage.TopLevelMessage` struct.

  Error resolution is as follows:

    - If the field `:message` is a string that starts with "rpc:" the error message will
      be converted to a top level message with the code `:service_unavailable` and the
      message #{inspect(@service_unavailable_message)}.

    - The `:request_id` and `:timestamp` keys are taken from the details.
  """
  @spec resolve(error_message(), resolution()) :: top_level_message()
  def resolve(%{message: "rpc:" <> _, details: details}, _resolution) do
    TopLevelMessage.create(:service_unavailable, @service_unavailable_message, details(details))
  end

  def resolve(%{code: code, message: message, details: details}, _resolution) do
    TopLevelMessage.create(code, message, details(details))
  end

  defp details(details) do
    if details do
      Map.take(details, [:request_id, :timestamp])
    else
      %{}
    end
  end
end
