defmodule AbsintheErrorMessage.FieldLevelMessage do
  @moduledoc """
  GraphQL Field Level Message
  """
  alias AbsintheErrorMessage.Serializer

  @type t :: %__MODULE__{
    message: binary() | nil,
    field: list(binary() | atom()) | nil
  }

  @type t_map :: %{
    message: binary() | nil,
    field: list(binary() | atom()) | nil
  }

  @type attrs :: map() | keyword()

  @enforce_keys [:message]
  defstruct @enforce_keys ++ [:field]

  @doc """
  Returns a struct.

  ### Examples

      iex> AbsintheErrorMessage.FieldLevelMessage.create(message: "expected an string representation of an integer", field: ["input", "id"])
      %AbsintheErrorMessage.FieldLevelMessage{
        message: "expected an string representation of an integer",
        field: ["input", "id"]
      }
  """
  @spec create(attrs()) :: t()
  def create(attrs), do: struct!(__MODULE__, attrs)

  @doc """
  Returns a struct.

  ### Examples

      iex> AbsintheErrorMessage.FieldLevelMessage.create("expected an string representation of an integer", ["input", "id"])
      %AbsintheErrorMessage.FieldLevelMessage{
        message: "expected an string representation of an integer",
        field: ["input", "id"]
      }
  """
  @spec create(binary(), list()) :: t()
  def create(message, field), do: create(message: message, field: field)

  @doc """
  Returns a map with values that can be serialized to a string.

  ### Examples

      iex> AbsintheErrorMessage.FieldLevelMessage.to_jsonable_map(%AbsintheErrorMessage.FieldLevelMessage{message: "expected an string representation of an integer", field: ["input", "id"]})
      %{
        message: "expected an string representation of an integer",
        field: ["input", "id"]
      }
  """
  @spec to_jsonable_map(list(t)) :: list(t_map())
  def to_jsonable_map(messages) when is_list(messages) do
    Enum.map(messages, &to_jsonable_map/1)
  end

  @spec to_jsonable_map(t()) :: t_map()
  def to_jsonable_map(%__MODULE__{} = field_level_message) do
    field_level_message
    |> Map.from_struct()
    |> Serializer.to_jsonable_map()
  end
end
