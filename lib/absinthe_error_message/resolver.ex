defmodule AbsintheErrorMessage.Resolver do
  @moduledoc """
  Interface for modules that implement the `AbsintheErrorMessage.Adapter.Resolver` behaviour.

  ### Usage

  ```elixir
  defmodule ExampleResolver do
    alias AbsintheErrorMessage.TopLevelMessage

    @behaviour AbsintheErrorMessage.Adapter.Resolver

    @impl AbsintheErrorMessage.Adapter.Resolver
    def resolve(%{code: code, message: message, details: details} = _error_message, resolution) do
      TopLevelMessage.create(code, message, details)
    end
  end

  iex> AbsintheErrorMessage.Resolver.resolve(%{code: :not_found, message: "no records found", details: %{params: %{id: 1}}}, resolver_module: ExampleResolver)
  %AbsintheErrorMessage.TopLevelMessage{message: "no records found", extensions: %{code: :not_found}}
  ```

  ### Writing Resolvers

  ```
  defmodule AbsintheErrorMessage.Resolvers.DefaultResolver do
    def resolve(%{code: code, message: message, details: details}, _resolution) do
      AbsintheErrorMessage.TopLevelMessage.create(code, message, details)
    end
  end
  ```
  """

  @type error_message :: AbsintheErrorMessage.error_message()
  @type options :: AbsintheErrorMessage.options()

  @default_module AbsintheErrorMessage.Resolvers.DefaultResolver

  @doc """
  Executes the callback function `c:AbsintheErrorMessage.Adapter.Resolver.resolve/2`.

  ### Options

      * `resolver_module` - The module to use for further operations. Defaults to #{inspect(@default_module)}.

  ### Examples

      AbsintheErrorMessage.Resolver.resolve(%{code: :not_found, message: "no records found", details: %{params: %{id: 1}}}, resolver_module: ExampleResolver)
  """
  @spec resolve(error_message(), Absinthe.Resolution.t(), options()) ::
    AbsintheErrorMessage.FieldLevelMessage.t() | AbsintheErrorMessage.TopLevelMessage.t()
  def resolve(error, resolution, opts \\ []) do
    resolver_module!(opts).resolve(error, resolution)
  end

  defp resolver_module!(opts) do
    opts[:resolver_module] || @default_module
  end
end
