import Config

config :absinthe_error_message,
  error_resolver: AbsintheErrorMessage.ErrorResolver,
  field_level_message_source: :user_errors
