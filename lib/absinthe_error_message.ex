defmodule AbsintheErrorMessage do
  @moduledoc File.read!("./README.md")

  alias AbsintheErrorMessage.{
    FieldLevelMessage,
    TopLevelMessage
  }

  @type schema :: map()
  @type replacement :: function() | any()
  @type schema_replacement :: {schema(), replacement()}
  @type change_params :: schema() | schema_replacement() | list(schema() | schema_replacement())
  @type options :: keyword()

  @type error_message :: ErrorMessageShorts.error_message()

  @doc """
  ...
  """
  @spec handle_error(
    response :: {:error, error_message() | list(error_message())} | {:ok, any()},
    change_params :: change_params(),
    options :: keyword()
  ) :: {:error, FieldLevelMessage.t() | TopLevelMessage.t()}
  @spec handle_error(
    response :: {:error, error_message() | list(error_message())} | {:ok, any()},
    change_params :: change_params()
  ) :: {:error, FieldLevelMessage.t() | TopLevelMessage.t()}
  def handle_error(response, change_params, options \\ [])

  def handle_error({:error, error_message}, change_params, options) do
    {:error, convert_to_message(error_message, change_params, options)}
  end

  def handle_error({:ok, _} = response, _change_params, _options) do
    response
  end

  @doc """
  Transforms the `code`, `message`, and `details` then
  change_params the result into a graphql error message.
  """
  @spec convert_to_message(
    error_message :: error_message() | list(error_message()),
    change_params :: change_params(),
    options :: options()
  ) :: FieldLevelMessage.t() | TopLevelMessage.t() | list(FieldLevelMessage.t() | TopLevelMessage.t())
  @spec convert_to_message(
    error_message :: error_message() | list(error_message()),
    change_params :: change_params()
  ) :: FieldLevelMessage.t() | TopLevelMessage.t() | list(FieldLevelMessage.t() | TopLevelMessage.t())
  def convert_to_message(error_message, change_params, options \\ [])

  def convert_to_message(error_messages, change_params, options) when is_list(error_messages) do
    Enum.map(error_messages, &convert_to_message(&1, change_params, options))
  end

  def convert_to_message(error_message, change_params, options) do
    error_message
    |> ErrorMessageShorts.change(change_params, options)
    |> ensure_message!()
  end

  defp ensure_message!(%TopLevelMessage{} = message), do: message
  defp ensure_message!(%FieldLevelMessage{} = message), do: message
  defp ensure_message!(term) do
    raise """
    Expected one of:

    * `AbsintheErrorMessage.TopLevelMessage` struct
    * `AbsintheErrorMessage.FieldLevelMessage` struct

    got:

    #{inspect(term, pretty: true)}
    """
  end
end
