defmodule AbsintheErrorMessage.Adapter.Resolver do
  alias AbsintheErrorMessage.{TopLevelMessage, FieldLevelMessage}

  @callback resolve(
    AbsintheErrorMessage.error_message(),
    Absinthe.Resolution.t()
  ) :: TopLevelMessage.t() | FieldLevelMessage.t()
end
