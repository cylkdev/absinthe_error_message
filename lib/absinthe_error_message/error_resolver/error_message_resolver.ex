defmodule AbsintheErrorMessage.ErrorResolver.ErrorMessageResolver do
  @moduledoc false

  alias AbsintheErrorMessage.{FieldLevelMessage, TopLevelMessage}
  alias AbsintheErrorMessage.ErrorResolver.Definition

  @logger_prefix "AbsintheErrorMessage.ErrorResolver.ErrorMessageResolver"

  @client_error_codes [
    :conflict,
    :forbidden,
    :not_found
  ]

  def build_messages(
    %{
      code: code,
      message: message,
      details: details
    } = error_message,
    %{arguments: arguments},
    opts \\ []
  ) do
    case Definition.find_definition(opts, error_message) do
      nil ->
        AbsintheErrorMessage.Utils.Logger.warning(
          @logger_prefix,
          "Expected a matching definition for:\n\n#{inspect(error_message, pretty: true)}"
        )

        error_message

      definition ->
        path = definition[:path] || []
        input = if path, do: get_in(arguments, path), else: arguments

        client_error_codes = Keyword.get(opts, :client_error_codes, @client_error_codes)

        if code in client_error_codes do
          build_field_level_messages(details, message, input, definition, path)
        else
          build_top_level_message(details, message, code, input, definition, path)
        end
    end
  end

  defp build_top_level_message(details, message, code, input, definition, path) do

  end

  defp build_field_level_messages(details, message, input, definition, path) do

  end

  # defp build_messages(details, error_message, input, definition, path, acc \\ [])

  # defp build_messages(details, error_message, input, definition, path, acc) do
  #   Enum.reduce(details, acc, fn details, acc ->
  #     build_message(details, error_message, input, definition, path, acc)
  #   end)
  # end

  # defp build_message(details, error_message, input, definition, path, acc) when is_list(details) do
  #   build_messages(details, error_message, input, definition, path, acc)
  # end

  # defp build_message(details, error_message, input, definition, path, acc) when is_map(details) do
  #   details
  #   |> Map.to_list()
  #   |> build_message(input, error_message, definition, path, acc)
  # end

  # defp build_message({field, errors}, error_message, input, definition, path, acc) do
  #   path = [field | path]
  #   keys = Keyword.get(definition, :keys, [])

  #   field_definition = Definition.find_field_definition(keys, field)

  #   if field_definition do
  #     field_alias = Keyword.get(field_definition, :alias, field)

  #     if is_list(input) do
  #       Enum.reduce(input, acc, fn input, acc ->
  #         case Map.get(input, field_alias) do
  #           nil -> acc
  #           field_input -> build_messages(errors, error_message, field_input, field_definition, path, acc)
  #         end
  #       end)
  #     else
  #       case Map.get(input, field_alias) do
  #         nil -> acc
  #         field_input -> build_messages(errors, error_message, field_input, field_definition, path, acc)
  #       end
  #     end
  #   else
  #     acc
  #   end
  # end

  # defp build_message(message, error_message, value, _definition, path, acc) when is_binary(message) do
  #   if value do
  #     message = FieldLevelMessage.create(message, Enum.reverse(path))

  #     [message | acc]
  #   else
  #     acc
  #   end
  # end
end
