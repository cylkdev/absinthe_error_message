defmodule AbsintheErrorMessage.Serializer do
  @moduledoc false

  @doc """
  Returns a map with values that can be serialized to a JSON string.

  ### Examples

      iex> AbsintheErrorMessage.Serializer.to_jsonable_map(%AbsintheErrorMessage.TopLevelMessage{
      ...>   message: "example",
      ...>   extensions: %{
      ...>     code: :not_found,
      ...>     date: ~D[2024-08-06],
      ...>     datetime: ~U[2024-08-06 09:00:00.000000Z],
      ...>     naive_datetime: ~N[2024-08-06 09:00:00.000000],
      ...>     time: ~T[00:00:00.000000],
      ...>     a_map: %{example: "data"},
      ...>     a_list_of_maps: [%{example: "data"}],
      ...>     a_tuple: {"foo", "bar"}
      ...>   }
      ...> })
      %{
        struct: "AbsintheErrorMessage.TopLevelMessage",
        data: %{
          message: "example",
          extensions: %{
            a_list_of_maps: [%{example: "data"}],
            a_map: %{example: "data"},
            a_tuple: ["foo", "bar"],
            code: "not_found",
            date: "2024-08-06",
            datetime: "2024-08-06T09:00:00.000000Z",
            naive_datetime: "2024-08-06T09:00:00.000000",
            time: "00:00:00.000000"
          }
        }
      }
  """
  def to_jsonable_map(%Date{} = date), do: Date.to_iso8601(date)

  def to_jsonable_map(%Time{} = time), do: Time.to_iso8601(time)

  def to_jsonable_map(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)

  def to_jsonable_map(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)

  def to_jsonable_map(%struct{} = struct_data) do
    %{
      struct: struct |> to_string() |> remove_elixir_prefix(),
      data: struct_data |> Map.from_struct() |> to_jsonable_map()
    }
  end

  def to_jsonable_map(data) when is_map(data) do
    Map.new(data, fn {k, v} -> {k, to_jsonable_map(v)} end)
  end

  def to_jsonable_map(data) when is_list(data) do
    Enum.map(data, &to_jsonable_map/1)
  end

  def to_jsonable_map(data) when is_tuple(data) do
    data |> Tuple.to_list() |> to_jsonable_map()
  end

  def to_jsonable_map(atom) when is_atom(atom) do
    atom |> Atom.to_string() |> remove_elixir_prefix()
  end

  def to_jsonable_map(value), do: to_string(value)

  defp remove_elixir_prefix(string), do: String.replace(string, "Elixir.", "")
end
