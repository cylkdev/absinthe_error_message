defmodule AbsintheErrorMessage.Middleware do
  @moduledoc """
  Absinthe Error Message Resolution Middleware

  This is a post-resolution middleware that converts application error messages
  to client error messages.

  ## Usage

  You can add this middleware to your schema:

  ```elixir
  defmodule YourApp.Schema do
    def middleware(middleware, _field, %Absinthe.Type.Object{identifier: identifier})
      when identifier in [:query, :subscription, :mutation] do
      middleware ++ [AbsintheErrorMessage.Middleware]
    end

    def middleware(middleware, _field, _object) do
      middleware
    end
  end
  ```

  You can add this middleware after the resolution of a field:

  ```elixir
  defmodule YourApp.Schema do
    use Absinthe.Schema.Notation

    object :example_mutations do
     field :user_update, :user_update_payload do
        arg :input, non_null(:user_update_input)

        resolve &YourApp.UserResolver.update/2

        middleware AbsintheErrorMessage.Middleware
      end
    end
  end
  ```

  ## Writing Resolvers

  See `AbsintheErrorMessage.Resolver` for more information.

  """
  alias AbsintheErrorMessage.{
    FieldLevelMessage,
    TopLevelMessage
  }

  @type error_message :: AbsintheErrorMessage.error_message()
  @type resolution :: Absinthe.Resolution.t()
  @type top_level_message :: AbsintheErrorMessage.TopLevelMessage.t()

  @behaviour Absinthe.Middleware

  @user_errors :user_errors
  @match_any [:*]

  @impl Absinthe.Middleware
  @doc """
  Implementation for `c:Absinthe.Middleware.call/2`.

  ### Examples

      AbsintheErrorMessage.Middleware.call(%Absinthe.Resolution{})
  """
  @spec call(Absinthe.Resolution.t(), Keyword.t()) :: Absinthe.Resolution.t()
  def call(
    %Absinthe.Resolution{
      state: :resolved,
      errors: errors,
      value: value
    } = resolution,
    opts \\ []
  ) do
    {
      top_level_messages,
      field_level_messages
    } = reduce_to_messages(errors, resolution, opts)

    case TopLevelMessage.to_jsonable_map(top_level_messages) do
      [] -> %{resolution | errors: [], value: error_payload(value, field_level_messages, opts)}
      errors -> %{resolution | errors: errors, value: nil}
    end
  end

  @doc false
  @spec resolve(any(), Absinthe.Resolution.t(), keyword()) :: any()
  def resolve(error, resolution, opts) do
    case (opts[:resolve] || @match_any) do
      func when is_function(func) ->
        func.(error, resolution)

      changeset ->
        Enum.reduce(changeset, error, fn
          {change_params, match_params, func}, error ->
            AbsintheErrorMessage.change(error, change_params, match_params, fn error ->
              func.(error, resolution)
            end)

          {change_params, match_params}, error ->
            AbsintheErrorMessage.change(error, change_params, match_params, fn error ->
              AbsintheErrorMessage.Resolver.resolve(error, resolution, opts)
            end)

          match_params, error ->
            AbsintheErrorMessage.change(error, [], match_params, fn error ->
              AbsintheErrorMessage.Resolver.resolve(error, resolution, opts)
            end)

        end)
    end
  end

  defp error_payload(value, [], _opts), do: value
  defp error_payload(value, messages, opts) do
    value = if value, do: value, else: %{}
    field_level_message_key = opts[:field_level_message_key] || @user_errors

    messages = FieldLevelMessage.to_jsonable_map(messages)

    Map.put(value, field_level_message_key, messages)
  end

  defp maybe_resolve(%module{} = message, _resolution, _opts)
    when module in [TopLevelMessage, FieldLevelMessage] do
    message
  end

  defp maybe_resolve(error, resolution, opts) do
    resolve(error, resolution, opts)
  end

  defp reduce_to_messages(errors, resolution, opts) when is_list(errors) do
    {top_level_messages, field_level_messages} =
      errors
      |> Enum.map(fn error -> maybe_resolve(error, resolution, opts) end)
      |> Enum.reduce({[], []}, &reduce_message/2)

    top_level_messages = Enum.reverse(top_level_messages)
    field_level_messages = Enum.reverse(field_level_messages)

    {top_level_messages, field_level_messages}
  end

  defp reduce_message(%TopLevelMessage{} = message, {top_level_messages, field_level_messages}) do
    {[message | top_level_messages], field_level_messages}
  end

  defp reduce_message(%FieldLevelMessage{} = message, {top_level_messages, field_level_messages}) do
    {top_level_messages, [message | field_level_messages]}
  end

  defp reduce_message(term, _) do
    raise "Expected a `TopLevelMessage` or `FieldLevelMessage` struct, got: #{inspect(term)}"
  end
end
