defmodule AbsintheErrorMessage.Middleware do
  @moduledoc """
  A post-resolution middleware that converts errors
  to graphql error messages.

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
    Config,
    FieldLevelMessage,
    TopLevelMessage,
    Middleware.ErrorResolver
  }

  @type errors :: list()
  @type error_message :: AbsintheErrorMessage.error_message()
  @type resolution :: Absinthe.Resolution.t()
  @type field_level_message :: AbsintheErrorMessage.FieldLevelMessage.t()
  @type top_level_message :: AbsintheErrorMessage.TopLevelMessage.t()
  @type opts :: keyword()

  @behaviour Absinthe.Middleware

  @default_field_level_message_source :user_errors

  @impl Absinthe.Middleware
  @doc """
  Implementation for `c:Absinthe.Middleware.call/2`.
  """
  @spec call(resolution :: resolution(), opts :: opts()) :: resolution()
  @spec call(resolution :: resolution()) :: resolution()
  def call(
    %Absinthe.Resolution{
      state: :resolved,
      errors: errors,
      value: value
    } = resolution,
    opts \\ []
  ) do
    case translate_errors(errors, resolution, opts) do
      {field_messages, []} ->
        field_messages = FieldLevelMessage.to_jsonable_map(field_messages)

        value = error_payload(value, field_messages, opts)

        %{resolution | value: value, errors: []}

      {[], top_messages} ->
        %{resolution | value: nil, errors: TopLevelMessage.to_jsonable_map(top_messages)}

    end
  end

  @doc false
  @spec translate_errors(
    errors :: errors(),
    resolution :: resolution(),
    opts :: opts()
  ) :: {list(field_level_message()), list(top_level_message())}
  @spec translate_errors(
    errors :: list(),
    resolution :: Absinthe.Resolution.t()
  ) :: {list(field_level_message()), list(top_level_message())}
  def translate_errors(errors, resolution, opts \\ []) do
    {field_messages, top_messages} = reduce_errors(errors, resolution, opts)

    {Enum.reverse(field_messages), Enum.reverse(top_messages)}
  end

  defp reduce_errors(errors, resolution, opts) do
    Enum.reduce(errors, {[], []}, &reduce_error(&1, resolution, &2, opts))
  end

  defp reduce_error(
    %FieldLevelMessage{} = message,
    _resolution,
    {field_messages, top_messages},
    _opts
  ) do
    {[message | field_messages], top_messages}
  end

  defp reduce_error(
    %TopLevelMessage{} = message,
    _resolution,
    {field_messages, top_messages},
    _opts
  ) do
    {field_messages, [message | top_messages]}
  end

  defp reduce_error(error, resolution, acc, opts) do
    error
    |> ErrorResolver.convert_to_message(resolution, opts)
    |> merge_messages(acc)
  end

  defp merge_messages(errors, {field_messages, top_messages}) do
    Enum.reduce(errors, {field_messages, top_messages}, fn
      %FieldLevelMessage{} = message, {field_messages, top_messages} -> {[message | field_messages], top_messages}
      %TopLevelMessage{} = message, {field_messages, top_messages} -> {field_messages, [message | top_messages]}
      term, _acc -> raise_invalid_message!(term)
    end)
  end

  defp error_payload(value, [], _opts), do: value
  defp error_payload(value, messages, opts) do
    key = field_level_message_source!(opts)
    value = if value, do: value, else: %{}

    Map.put(value, key, messages)
  end

  defp raise_invalid_message!(term) do
    raise """
    Expected one of:

    * `AbsintheErrorMessage.TopLevelMessage` struct
    * `AbsintheErrorMessage.FieldLevelMessage` struct

    got:

    #{inspect(term, pretty: true)}
    """
  end

  defp field_level_message_source!(opts) do
    with nil <- opts[:field_level_message_source],
      nil <- Config.field_level_message_source() do
      @default_field_level_message_source
    end
  end
end
