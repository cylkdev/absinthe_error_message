defmodule AbsintheErrorMessage.ErrorResolver.Definition do
  def find_field_definition(keys, field) do
    Enum.reduce_while(keys, nil, fn
      {key, field_definition}, acc -> if key === field, do: {:halt, field_definition}, else: {:cont, acc}
      key, acc -> if key === field, do: {:halt, []}, else: {:cont, acc}
    end)
  end

  def find_definition(opts, error) do
    opts
    |> Keyword.get(:definition, [])
    |> Enum.find(&SubstituteX.compare?(error, &1[:match]))
  end
end
