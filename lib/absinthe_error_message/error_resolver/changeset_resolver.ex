if AbsintheErrorMessage.Utils.application_loaded?(:ecto) do
  defmodule AbsintheErrorMessage.ErrorResolver.ChangesetResolver do
    @moduledoc false

    alias AbsintheErrorMessage.FieldLevelMessage
    alias AbsintheErrorMessage.ErrorResolver.Definition

    @logger_prefix "AbsintheErrorMessage.ErrorResolver.ChangesetResolver"

    def build_messages(changeset, %{arguments: arguments}, opts \\ []) do
      case Definition.find_definition(opts, changeset) do
        nil ->
          AbsintheErrorMessage.Utils.Logger.warning(
            @logger_prefix,
            "Expected a matching definition for:\n\n#{inspect(changeset, pretty: true)}"
          )

          changeset

        definition ->
          path = definition[:path] || []
          input = if path, do: get_in(arguments, path), else: arguments

          changeset
          |> errors_on_changeset()
          |> build_field_level_messages(input, definition, path)
      end
    end

    defp build_field_level_messages(errors, input, definition, path, acc \\ [])

    defp build_field_level_messages(errors, input, definition, path, acc) do
      errors
      |> Enum.reduce(acc, fn error, acc -> build_field_level_message(error, input, definition, path, acc) end)
      |> Enum.reverse()
    end

    defp build_field_level_message(errors, input, definition, path, acc) when is_list(errors) do
      build_field_level_messages(errors, input, definition, path, acc)
    end

    defp build_field_level_message(error, input, definition, path, acc) when is_map(error) do
      error
      |> Map.to_list()
      |> build_field_level_message(input, definition, path, acc)
    end

    defp build_field_level_message({field, errors}, input, definition, path, acc) do
      path = [field | path]
      keys = Keyword.get(definition, :keys, [])

      field_definition = Definition.find_field_definition(keys, field)

      if field_definition do
        field_alias = Keyword.get(field_definition, :alias, field)

        if is_list(input) do
          Enum.reduce(input, acc, fn input, acc ->
            case Map.get(input, field_alias) do
              nil -> acc
              field_input -> build_field_level_messages(errors, field_input, field_definition, path, acc)
            end
          end)
        else
          case Map.get(input, field_alias) do
            nil -> acc
            field_input -> build_field_level_messages(errors, field_input, field_definition, path, acc)
          end
        end
      else
        acc
      end
    end

    defp build_field_level_message(message, value, _definition, path, acc) when is_binary(message) do
      if value do
        message = FieldLevelMessage.create(message, Enum.reverse(path))

        [message | acc]
      else
        acc
      end
    end

    defp errors_on_changeset(changeset) do
      Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
        Regex.replace(~r"%{(\w+)}", message, fn _, key ->
          atom_key = String.to_existing_atom(key)
          opts |> Keyword.get(atom_key, key) |> to_string()
        end)
      end)
    end
  end
end
