defmodule AbsintheErrorMessage do
  @moduledoc File.read!("./README.md")

  alias AbsintheErrorMessage.{
    FieldLevelMessage,
    TopLevelMessage
  }

  @type error_message :: ErrorMessageShorts.error_message()
  @type params :: map() | list()
  @type replacement :: function() | term()
  @type options :: keyword()

  @doc """
  Transforms the `code`, `message`, and `details` then change_params the result into a graphql error message.

  ### Examples

      iex> AbsintheErrorMessage.change(
      ...>   %{code: :not_found, message: "no records found"},
      ...>   [],
      ...>   %{code: :not_found},
      ...>   %AbsintheErrorMessage.TopLevelMessage{message: "service currently unavailable", extensions: %{code: :service_unavailable}}
      ...> )
      %AbsintheErrorMessage.TopLevelMessage{message: "service currently unavailable", extensions: %{code: :service_unavailable}}

      iex> AbsintheErrorMessage.change(
      ...>   %{code: :not_found, message: "no records found"},
      ...>   %{message: %{"no records" => %{=~: "service currently unavailable"}}},
      ...>   %{code: :not_found},
      ...>   fn error_message -> %AbsintheErrorMessage.TopLevelMessage{message: error_message.message, extensions: %{code: :service_unavailable}} end
      ...> )
      %AbsintheErrorMessage.TopLevelMessage{message: "service currently unavailable", extensions: %{code: :service_unavailable}}
  """
  @spec change(term(), params(), params(), replacement()) :: FieldLevelMessage.t() | TopLevelMessage.t()
  def change(term, change_params, match_params, replacement) do
    term
    |> ErrorMessageShorts.change(change_params)
    |> ErrorMessageShorts.change(match_params, replacement)
  end

  @doc """
  See `&AbsintheErrorMessage.change/4` for more information.

  ### Examples

      iex> AbsintheErrorMessage.change(%{code: :not_found, message: "no records found"}, %{code: :not_found}, %AbsintheErrorMessage.TopLevelMessage{message: "service currently unavailable", extensions: %{code: :service_unavailable}})
      %AbsintheErrorMessage.TopLevelMessage{message: "service currently unavailable", extensions: %{code: :service_unavailable}}

      iex> AbsintheErrorMessage.change(%{code: :not_found, message: "no records found"}, [%{code: :not_found}], %AbsintheErrorMessage.TopLevelMessage{message: "service currently unavailable", extensions: %{code: :service_unavailable}})
      %AbsintheErrorMessage.TopLevelMessage{message: "service currently unavailable", extensions: %{code: :service_unavailable}}
  """
  @spec change(term(), params(), replacement()) :: FieldLevelMessage.t() | TopLevelMessage.t()
  def change(term, params, replacement) do
    params
    |> List.wrap()
    |> Enum.reduce(term, fn
      {change_params, match_params}, term -> change(term, change_params, match_params, replacement)
      match_params, term -> change(term, [], match_params, replacement)
    end)
  end

  @doc """
  See `&AbsintheErrorMessage.change/4` for more information.

  ### Examples

      iex> AbsintheErrorMessage.change(%{code: :not_found, message: "no records found"}, %AbsintheErrorMessage.TopLevelMessage{message: "service currently unavailable", extensions: %{code: :service_unavailable}})
      %AbsintheErrorMessage.TopLevelMessage{message: "service currently unavailable", extensions: %{code: :service_unavailable}}

      iex> AbsintheErrorMessage.change(
      ...>   %{code: :not_found, message: "no records found"},
      ...>   {
      ...>     %{code: :not_found},
      ...>     %AbsintheErrorMessage.TopLevelMessage{message: "service currently unavailable", extensions: %{code: :service_unavailable}}
      ...>   }
      ...> )
      %AbsintheErrorMessage.TopLevelMessage{message: "service currently unavailable", extensions: %{code: :service_unavailable}}

      iex> AbsintheErrorMessage.change(
      ...>   %{code: :not_found, message: "no records found"},
      ...>   [
      ...>     {
      ...>       %{code: :not_found},
      ...>       %AbsintheErrorMessage.TopLevelMessage{message: "service currently unavailable", extensions: %{code: :service_unavailable}}
      ...>     }
      ...>   ]
      ...> )
      %AbsintheErrorMessage.TopLevelMessage{message: "service currently unavailable", extensions: %{code: :service_unavailable}}

      iex> AbsintheErrorMessage.change(
      ...>   %{code: :not_found, message: "no records found"},
      ...>   [
      ...>     {
      ...>       %{message: %{"no records found" => "replaced message"}},
      ...>       %{code: :not_found},
      ...>       fn %{message: message} ->
      ...>         %AbsintheErrorMessage.TopLevelMessage{message: message, extensions: %{code: :service_unavailable}}
      ...>       end
      ...>     }
      ...>   ]
      ...> )
      %AbsintheErrorMessage.TopLevelMessage{message: "replaced message", extensions: %{code: :service_unavailable}}
  """
  @spec change(term(), params() | list()) :: FieldLevelMessage.t() | TopLevelMessage.t()
  def change(term, params) do
    params
    |> List.wrap()
    |> Enum.reduce(term, fn
      {change_params, match_params, replacement}, term -> change(term, change_params, match_params, replacement)
      {match_params, replacement}, term -> change(term, [], match_params, replacement)
      replacement, term -> change(term, [], [:*], replacement)
    end)
  end

  @doc """
  This function is simple wrapper function that calls `change/2`
  on the `term` in an error status tuple `{:error, term()}`.

  ### Examples

      iex> AbsintheErrorMessage.handle_error_response(
      ...>   fn error ->
      ...>     AbsintheErrorMessage.TopLevelMessage.create(error.code, error.message, error.details)
      ...>   end,
      ...>   {:error, %{code: :not_found, message: "message", details: %{params: %{id: 1}}}}
      ...> )
      {:error, %AbsintheErrorMessage.TopLevelMessage{message: "message", extensions: %{code: :not_found, params: %{id: 1}}}}
  """
  @spec handle_error_response(params(), {:error, term()} | {:ok, term()} | function()) ::
    {:error, TopLevelMessage.t() | FieldLevelMessage.t()} | {:ok, term()}
  def handle_error_response(params, func) when is_function(func), do: handle_error_response(params, func.())
  def handle_error_response(params, {:error, error}), do: {:error, change(error, params)}
  def handle_error_response(_params, {:ok, _} = response), do: response
end
