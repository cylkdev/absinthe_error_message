defmodule AbsintheErrorMessage.MiddlewareTest do
  use ExUnit.Case, async: true
  doctest AbsintheErrorMessage.Middleware
  import ExUnit.CaptureLog

  alias AbsintheErrorMessage.{FieldLevelMessage, TopLevelMessage}
  alias AbsintheErrorMessage.Middleware

  defmodule MockTestResolver do
    alias AbsintheErrorMessage.FieldLevelMessage

    @behaviour AbsintheErrorMessage.Adapter.Resolver

    @impl AbsintheErrorMessage.Adapter.Resolver
    def resolve(%{code: :not_found}, %{arguments: %{input: input}} = _resolution) do
      FieldLevelMessage.create(
        "user with id '#{input.id}' not found",
        ["input", "id"]
      )
    end
  end

  describe "&call/2:" do
    test "returns top level message when error is a error message map" do
      assert %Absinthe.Resolution{
        state: :resolved,
        errors: errors,
        value: nil
      } =
        Middleware.call(%Absinthe.Resolution{
          state: :resolved,
          errors: [
            %{
              code: :not_found,
              message: "no records found",
              details: %{timestamp: "2024-08-06 03:54:10.416863Z"}
            }
          ]
        })

      assert [
        %{
          message: "no records found",
          extensions: %{
            code: "NOT_FOUND",
            request_id: nil,
            timestamp: "2024-08-06 03:54:10.416863Z"
          }
        }
      ] = errors
    end

    test "returns top level message when error is a string" do
      assert %Absinthe.Resolution{
        state: :resolved,
        errors: errors,
        value: nil
      } =
        Middleware.call(%Absinthe.Resolution{
          state: :resolved,
          errors: ["no records found"]
        })

      assert [
        %{
          message: "no records found",
          extensions: %{
            code: "INTERNAL_SERVER_ERROR",
            request_id: nil,
            timestamp: _timestamp
          }
        }
      ] = errors
    end

    test "returns service unavailable by if message starts with `rpc:` error" do
      assert %Absinthe.Resolution{
        state: :resolved,
        errors: errors,
        value: nil
      } =
        Middleware.call(%Absinthe.Resolution{
          state: :resolved,
          errors: [
            %{
              code: :bad_request,
              message: "rpc: one of more arguments are invalid",
              details: %{timestamp: "2024-08-06 03:54:10.416863Z"}
            }
          ]
        })

      assert [
        %{
          message: "service unavailable, please try again in a few minutes",
          extensions: %{
            code: "SERVICE_UNAVAILABLE",
            request_id: nil,
            timestamp: "2024-08-06 03:54:10.416863Z"
          }
        }
      ] = errors
    end

    test "puts a `TopLevelMessage` struct is added to the top-most errors list" do
      assert %Absinthe.Resolution{
        state: :resolved,
        errors: errors,
        value: nil
      } =
        Middleware.call(%Absinthe.Resolution{
          state: :resolved,
          errors: [
            %TopLevelMessage{message: "record not found"}
          ]
        })

      assert [
        %{
          message: "record not found",
          extensions: %{
            request_id: nil,
            timestamp: _timestamp
          }
        }
      ] = errors
    end

    test "puts a `FieldLevelMessage` struct is added to the payload" do
      assert %Absinthe.Resolution{
        state: :resolved,
        errors: [],
        value: value
      } =
        Middleware.call(%Absinthe.Resolution{
          state: :resolved,
          errors: [
            %FieldLevelMessage{message: "record not found", field: ["input", "id"]}
          ]
        })

      assert %{
        user_errors: [
          %{
            message: "record not found",
            field: ["input", "id"]
          }
        ]
      } = value
    end

    test "returns default error message if error is not a `TopLevelMessage` or `FieldLevelMessage` struct" do
      func =
        fn ->
          assert %Absinthe.Resolution{
            state: :resolved,
            errors: errors,
            value: nil
          } =
            Middleware.call(%Absinthe.Resolution{
              state: :resolved,
              errors: [
                :invalid_error
              ]
            })

          assert [
            %{
              extensions: %{
                code: "INTERNAL_SERVER_ERROR",
                request_id: nil,
                timestamp: _timestamp
              },
              message: "oops something unexpected happened, please try again in a few minutes"
            }
          ] = errors
        end

      assert capture_log([level: :warning], func) =~ ~r|(.*)Did not receive a valid error message(.*)|
    end

    test "transform error message without change using option `:resolve` callback function" do
      assert %Absinthe.Resolution{
        state: :resolved,
        errors: [],
        value: %{
          user_errors: [
            %{field: ["input", "id"], message: "no records found"}
          ]
        }
      } =
        Middleware.call(
          %Absinthe.Resolution{
            state: :resolved,
            errors: [
              %{
                code: :not_found,
                message: "no records found",
                details: %{timestamp: "2024-08-06 03:54:10.416863Z"}
              }
            ]
          },
          resolve: fn error_message, _resolution ->
            AbsintheErrorMessage.FieldLevelMessage.create(
              error_message.message,
              ["input", "id"]
            )
          end
        )
    end

    test "transform error message using {changes(), match(), replacement()} option `:resolve`" do
      assert %Absinthe.Resolution{
        state: :resolved,
        errors: [],
        value: %{
          user_errors: [
            %{field: ["input", "id"], message: "no records found"}
          ]
        }
      } =
        Middleware.call(
          %Absinthe.Resolution{
            state: :resolved,
            errors: [
              %{
                code: :not_found,
                message: "no records found",
                details: %{timestamp: "2024-08-06 03:54:10.416863Z"}
              }
            ]
          },
          resolve: [
            {
              [],
              %{code: :not_found},
              fn error_message, _resolution ->
                AbsintheErrorMessage.FieldLevelMessage.create(
                  error_message.message,
                  ["input", "id"]
                )
              end
            }
          ]
        )
    end

    test "transform error message using options `:resolver_module` and `:resolve`" do
      assert %Absinthe.Resolution{
        state: :resolved,
        arguments: %{input: %{id: 1}},
        errors: [],
        value: %{
          user_errors: [
            %{
              field: ["input", "id"],
              message: "user with id '1' not found"
            }
          ]
        }
      } =
        Middleware.call(
          %Absinthe.Resolution{
            state: :resolved,
            arguments: %{input: %{id: 1}},
            errors: [
              %{
                code: :not_found,
                message: "no records found",
                details: %{timestamp: "2024-08-06 03:54:10.416863Z"}
              }
            ]
          },
          resolver_module: MockTestResolver,
          resolve: [
            {[], %{code: :not_found}}
          ]
        )
    end

    test "raises if resolver module does not return a top or field level message" do
      func =
        fn ->
          Middleware.call(
            %Absinthe.Resolution{
              state: :resolved,
              arguments: %{input: %{id: 1}},
              errors: [
                %{
                  code: :not_found,
                  message: "no records found",
                  details: %{timestamp: "2024-08-06 03:54:10.416863Z"}
                }
              ]
            },
            resolve: fn _error_message, _resolution ->
              "invalid_response"
            end
          )
        end

      assert_raise(RuntimeError, ~r|Expected a `TopLevelMessage` or `FieldLevelMessage` struct|, func)
    end
  end
end
