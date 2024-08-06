defmodule AbsintheErrorMessage.TopLevelMessage do
  @moduledoc """
  GraphQL Top-Level Message
  """
  alias AbsintheErrorMessage.Serializer

  @type t :: %__MODULE__{
    message: binary() | nil,
    extensions: map() | nil
  }

  @type t_map :: %{
    message: binary() | nil,
    extensions: map() | nil
  }

  @type attrs :: map() | keyword()

  @enforce_keys [:message]
  defstruct @enforce_keys ++ [extensions: %{}]

  @doc """
  Returns a struct

  ### Examples

      iex> AbsintheErrorMessage.TopLevelMessage.create(message: "an unexpected error occurred", extensions: %{code: :internal_server_error})
      %AbsintheErrorMessage.TopLevelMessage{
        message: "an unexpected error occurred",
        extensions: %{code: :internal_server_error}
      }
  """
  @spec create(attrs()) :: t()
  def create(attrs), do: struct!(__MODULE__, attrs)

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
  @spec create(atom(), binary(), nil | map()) :: t()
  def create(code, message, extensions) do
    extensions =
      if extensions do
        Map.put(extensions, :code, code)
      else
        %{code: code}
      end

    create(message: message, extensions: extensions)
  end

  @doc """
  See `&create/3` for documentation.

  ### Examples

      iex> AbsintheErrorMessage.TopLevelMessage.create(:not_found, "no records found")
      %AbsintheErrorMessage.TopLevelMessage{message: "no records found", extensions: %{code: :not_found}}
  """
  @spec create(atom(), binary()) :: t()
  def create(code, message) do
    create(code, message, nil)
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
    state =
      state
      |> Map.from_struct()
      |> Serializer.to_jsonable_map()

    timestamp = DateTime.to_string(DateTime.utc_now())

    extensions =
      (extensions || %{})
      |> upcase_code()
      |> Map.put(:request_id, Logger.metadata()[:request_id])
      |> Map.put_new(:timestamp, timestamp)

    %{state | extensions: extensions}
  end

  defp upcase_code(extensions) do
    case Map.get(extensions, :code) do
      nil -> extensions
      code -> Map.put(extensions, :code, upcase(code))
    end
  end

  defp upcase(atom) when is_atom(atom), do: atom |> Atom.to_string() |> upcase()
  defp upcase(string), do: String.upcase(string)
end
