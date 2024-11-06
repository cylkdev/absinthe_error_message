defmodule AbsintheErrorMessage.ErrorResolver do
  @moduledoc """
  ...
  """

  alias AbsintheErrorMessage.Config
  alias AbsintheErrorMessage.ErrorResolver.{
    ChangesetResolver,
    ErrorMessageResolver
  }

  def convert_to_message(errors, resolution, opts) when is_list(errors) do
    opts = Keyword.merge(default_opts(), opts)

    Enum.reduce(errors, [], fn error, acc ->
      acc ++ convert_to_message(error, resolution, opts)
    end)
  end

  if AbsintheErrorMessage.Utils.application_loaded?(:ecto) do
    def convert_to_message(%Ecto.Changeset{} = changeset, resolution, opts) do
      ChangesetResolver.build_messages(changeset, resolution, opts)
    end
  end

  if AbsintheErrorMessage.Utils.application_loaded?(:error_message) do
    def convert_to_message(%ErrorMessage{} = error_message, resolution, opts) do
      ErrorMessageResolver.build_messages(error_message, resolution, opts)
    end
  end

  defp default_opts do
    Application.get_env(Config.app(), __MODULE__, [])
  end

  # defp build_messages(%Ecto.Changeset{} = changeset, %{arguments: args}, definition, acc) do
  #   path = definition[:path] || []
  #   input = if path, do: get_in(args, path), else: args

  #   changeset
  #   |> errors_on_changeset()
  #   |> build_changeset_messages(input, definition, path, acc)
  # end

  # defp build_changeset_messages(errors, input, definition, path, acc) do
  #   Enum.reduce(errors, acc, fn error, acc ->
  #     reduce_changeset_error(error, input, definition, path, acc)
  #   end)
  # end

  # defp reduce_changeset_error(errors, input, definition, path, acc) when is_list(errors) do
  #   build_changeset_messages(errors, input, definition, path, acc)
  # end

  # defp reduce_changeset_error(errors, input, definition, path, acc) when is_map(errors) do
  #   errors
  #   |> Map.to_list()
  #   |> reduce_changeset_error(input, definition, path, acc)
  # end

  # defp reduce_changeset_error({field, errors}, input, definition, path, acc) do
  #   path = [field | path]
  #   keys = Keyword.get(definition, :keys, [])

  #   field_definition = find_field_definition(keys, field)

  #   if field_definition do
  #     field_alias = Keyword.get(field_definition, :alias, field)

  #     if is_list(input) do
  #       Enum.reduce(input, acc, fn input, acc ->
  #         case Map.get(input, field_alias) do
  #           nil -> acc
  #           field_input -> build_changeset_messages(errors, field_input, field_definition, path, acc)
  #         end
  #       end)
  #     else
  #       case Map.get(input, field_alias) do
  #         nil -> acc
  #         field_input -> build_changeset_messages(errors, field_input, field_definition, path, acc)
  #       end
  #     end
  #   else
  #     acc
  #   end
  # end

  # defp reduce_changeset_error(message, value, _definition, path, acc) when is_binary(message) do
  #   if value do
  #     message = FieldLevelMessage.create(message, Enum.reverse(path))

  #     [message | acc]
  #   else
  #     acc
  #   end
  # end

  # defp errors_on_changeset(changeset) do
  #   Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
  #     Regex.replace(~r"%{(\w+)}", message, fn _, key ->
  #       atom_key = String.to_existing_atom(key)
  #       opts |> Keyword.get(atom_key, key) |> to_string()
  #     end)
  #   end)
  # end

  # defp find_field_definition(keys, field) do
  #   Enum.reduce_while(keys, nil, fn
  #     {key, field_definition}, acc -> if key === field, do: {:halt, field_definition}, else: {:cont, acc}
  #     key, acc -> if key === field, do: {:halt, []}, else: {:cont, acc}
  #   end)
  # end

  # defp find_definition(opts, error) do
  #   opts
  #   |> Keyword.get(:definition, [])
  #   |> Enum.find(&SubstituteX.compare?(error, &1[:match]))
  # end
end
