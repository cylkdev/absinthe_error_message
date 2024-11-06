defmodule AbsintheErrorMessage.TopLevelMessage do
  @moduledoc """
  GraphQL Top-Level Message
  """
  alias AbsintheErrorMessage.Serializer

  @type code :: atom()
  @type message :: binary()
  @type extensions :: map()
  @type attrs :: map() | keyword()
  @type error_message :: ErrorMessageShorts.error_message()

  @type t :: %__MODULE__{message: message() | nil, extensions: extensions() | nil}

  @type t_map :: %{message: message() | nil, extensions: extensions() | nil}

  @enforce_keys [:message]

  defstruct @enforce_keys ++ [
    extensions: %{}
  ]

  @doc """
  Returns a struct

  ### Examples

      iex> AbsintheErrorMessage.TopLevelMessage.create_struct(message: "an unexpected error occurred", extensions: %{code: :internal_server_error})
      %AbsintheErrorMessage.TopLevelMessage{
        message: "an unexpected error occurred",
        extensions: %{code: :internal_server_error}
      }
  """
  @spec create_struct(attrs()) :: t()
  def create_struct(attrs), do: struct!(__MODULE__, attrs)

  @doc """
  Returns a struct.

  ### Examples

      iex> AbsintheErrorMessage.TopLevelMessage.create(:not_found, "no records found", %{id: 1})
      %AbsintheErrorMessage.TopLevelMessage{message: "no records found", extensions: %{code: :not_found, id: 1}}

      iex> AbsintheErrorMessage.TopLevelMessage.create(:not_found, "no records found", nil)
      %AbsintheErrorMessage.TopLevelMessage{message: "no records found", extensions: %{code: :not_found}}

      iex> AbsintheErrorMessage.TopLevelMessage.create(:not_found, "no records found")
      %AbsintheErrorMessage.TopLevelMessage{message: "no records found", extensions: %{code: :not_found}}
  """
  @spec create(
    code :: code(),
    message :: message(),
    extensions :: extensions() | nil
  ) :: t()
  @spec create(
    code :: code(),
    message :: message()
  ) :: t()
  def create(code, message, extensions \\ nil) do
    extensions =
      if extensions do
        Map.put(extensions, :code, code)
      else
        %{code: code}
      end

    create_struct(message: message, extensions: extensions)
  end

  @doc """
  Converts a error message to a top level message.

  ### Examples

      iex> AbsintheErrorMessage.TopLevelMessage.convert_to_message(%{message: "no records found."})
      %AbsintheErrorMessage.TopLevelMessage{
        message: "no records found.",
        extensions: %{code: :internal_server_error}
      }

      iex> AbsintheErrorMessage.TopLevelMessage.convert_to_message(%{code: :not_found, message: "no records found."})
      %AbsintheErrorMessage.TopLevelMessage{
        message: "no records found.",
        extensions: %{code: :not_found}
      }

      iex> AbsintheErrorMessage.TopLevelMessage.convert_to_message(%{code: :not_found, message: "no records found.", details: %{request_id: "request_id"}})
      %AbsintheErrorMessage.TopLevelMessage{
        message: "no records found.",
        extensions: %{code: :not_found, request_id: "request_id"}
      }

      iex> AbsintheErrorMessage.TopLevelMessage.convert_to_message("no records found.")
      %AbsintheErrorMessage.TopLevelMessage{
        message: "no records found.",
        extensions: %{code: :internal_server_error}
      }
  """
  @spec convert_to_message(error_message :: error_message()) :: AbsintheErrorMessage.TopLevelMessage.t()
  def convert_to_message(error_message) do
    error_message = ErrorMessageShorts.validate!(error_message)

    create(error_message.code, error_message.message, error_message.details)
  end

  @doc """
  Returns a map with values that can be serialized to a string.

  ### Examples

      iex> AbsintheErrorMessage.TopLevelMessage.to_jsonable_map(
      ...>   %AbsintheErrorMessage.TopLevelMessage{
      ...>     message: "an unexpected error occurred",
      ...>     extensions: %{
      ...>       code: :internal_server_error,
      ...>       timestamp: "2024-08-06 02:56:17.530410Z"
      ...>     }
      ...>   }
      ...> )
      %{
        message: "an unexpected error occurred",
        extensions: %{
          code: "INTERNAL_SERVER_ERROR",
          request_id: nil,
          timestamp: "2024-08-06 02:56:17.530410Z"
        }
      }
  """
  @spec to_jsonable_map(list(t)) :: list(t_map())
  def to_jsonable_map(messages) when is_list(messages) do
    Enum.map(messages, &to_jsonable_map/1)
  end

  @spec to_jsonable_map(t()) :: t_map()
  def to_jsonable_map(%__MODULE__{extensions: extensions} = state) do
    state = state |> Map.from_struct() |> Serializer.to_jsonable_map()

    extensions =
      (extensions || %{})
      |> upcase_extensions_code()
      |> Map.put(:request_id, Logger.metadata()[:request_id])
      |> Map.put_new(:timestamp, DateTime.to_string(DateTime.utc_now()))

    %{state | extensions: extensions}
  end

  defp upcase_extensions_code(extensions) do
    case Map.get(extensions, :code) do
      nil -> extensions
      code -> Map.put(extensions, :code, upcase(code))
    end
  end

  defp upcase(atom) when is_atom(atom), do: atom |> Atom.to_string() |> upcase()
  defp upcase(string), do: String.upcase(string)
end
