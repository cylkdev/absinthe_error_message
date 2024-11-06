defmodule AbsintheErrorMessage.Config do
  @moduledoc false
  @app :absinthe_error_message

  @doc false
  @spec app :: atom()
  def app, do: @app

  @doc false
  @spec error_resolver :: module() | nil
  def error_resolver do
    Application.get_env(@app, :error_resolver)
  end

  @doc false
  @spec field_level_message_source :: atom() | nil
  def field_level_message_source do
    Application.get_env(@app, :field_level_message_source)
  end
end
