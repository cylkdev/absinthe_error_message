defmodule AbsintheErrorMessage.Middleware.ErrorResolver do
  @moduledoc """
  ...
  """

  alias AbsintheErrorMessage.{
    Config,
    FieldLevelMessage,
    TopLevelMessage
  }

  @type error :: any()
  @type resolution :: Absinthe.Resolution.t()
  @type opts :: keyword()

  @default_adapter AbsintheErrorMessage.ErrorResolver

  @doc """
  ...
  """
  @callback convert_to_message(
    error :: error(),
    resolution :: resolution(),
    opts :: opts()
  ) :: FieldLevelMessage.t() | TopLevelMessage.t()

  @doc """
  ...
  """
  @spec convert_to_message(
    error :: error(),
    resolution :: resolution(),
    opts :: opts()
  ) :: FieldLevelMessage.t() | TopLevelMessage.t() | list(FieldLevelMessage.t() | TopLevelMessage.t())
  @spec convert_to_message(
    error :: error(),
    resolution :: resolution()
  ) :: FieldLevelMessage.t() | TopLevelMessage.t() | list(FieldLevelMessage.t() | TopLevelMessage.t())
  def convert_to_message(error, resolution, opts \\ []) do
    adapter!(opts).convert_to_message(error, resolution, opts)
  end

  defp adapter!(opts) do
    with nil <- opts[:error_resolver],
      nil <- Config.error_resolver() do
      @default_adapter
    end
  end
end
