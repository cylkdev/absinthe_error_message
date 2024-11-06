defmodule AbsintheErrorMessage.MiddlewareTest do
  use ExUnit.Case, async: true
  doctest AbsintheErrorMessage.Middleware

  alias Absinthe.Resolution
  alias AbsintheErrorMessage.{
    FieldLevelMessage,
    Middleware,
    TopLevelMessage
  }
  alias AbsintheErrorMessage.Support.Schemas.Post

  describe "call " do
    test "puts field level message in value when payload is not nil" do
      resolution =
        %Resolution{
          state: :resolved,
          value: %{
            account: %{id: 1}
          },
          errors: [
            %FieldLevelMessage{
              message: "no records found.",
              field: [:id]
            }
          ]
        }

      assert %Resolution{value: value} = Middleware.call(resolution)

      assert %{
        account: %{id: 1},
        user_errors: [
          %{
            message: "no records found.",
            field: ["id"]
          }
        ]
      } === value
    end

    test "puts field level message in value when payload is nil" do
      resolution =
        %Resolution{
          state: :resolved,
          value: nil,
          errors: [
            %FieldLevelMessage{
              message: "no records found.",
              field: [:id]
            }
          ]
        }

      assert %Resolution{value: value} = Middleware.call(resolution)

      assert %{user_errors: [%{message: "no records found.", field: ["id"]}]} === value
    end

    test "puts top level message struct in errors and nullifies value" do
      resolution =
        %Resolution{
          state: :resolved,
          value: nil,
          errors: [
            %TopLevelMessage{
              message: "no records found.",
              extensions: %{
                code: :not_found
              }
            }
          ]
        }

      assert %Resolution{value: value, errors: errors} = Middleware.call(resolution)

      assert is_nil(value)

      assert [
        %{
          message: "no records found.",
          extensions: %{
            code: "NOT_FOUND",
            request_id: nil,
            timestamp: _
          }
        }
      ] = errors
    end

    test "returns field level messages when error is a changeset" do
      changeset =
        Post.changeset(%Post{}, %{
          title: "foo",
          comments: [
            %{
              body: "bar",
              post: %{
                title: "qux"
              }
            }
          ]
        })

      resolution =
        %Resolution{
          arguments: %{
            input: %{
              title: "foo",
              comments: [
                %{
                  body: "bar",
                  post: %{title: "qux"}
                }
              ]
            }
          },
          state: :resolved,
          value: nil,
          errors: [changeset]
        }

      definition =
        [
          [
            match: %{
              is_struct: Ecto.Changeset,
              data: %{is_struct: AbsintheErrorMessage.Support.Schemas.Post}
            },
            path: [:input],
            keys: [
              :title,
              messages: [
                alias: :comments,
                keys: [
                  :body,
                  post: [
                    keys: [
                      :title
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]

      resolution = Middleware.call(resolution, definition: definition)

      assert %Resolution{
        state: :resolved,
        arguments: %{
          input: %{
            title: "foo",
            comments: [
              %{
                body: "bar",
                post: %{title: "qux"}
              }
            ]
          }
        },
        value: %{
          user_errors: [
            %{
              field: ["input", "title"],
              message: "should be at least 6 character(s)"
            },
            %{
              field: ["input", "comments", "post", "title"],
              message: "should be at least 6 character(s)"
            },
            %{
              field: ["input", "comments", "body"],
              message: "should be at least 6 character(s)"
            }
          ]
        }
      } = resolution
    end

    test "returns top level messages when error message code is not a user error code" do
      error_message =
        ErrorMessage.not_found("no records found", %{
          schema: AbsintheErrorMessage.Support.Schemas.Post,
          params: %{
            id: 1,
            users: [
              %{
                id: 2,
                post: %{
                  body: "body"
                }
              }
            ]
          }
        })

      resolution =
        %Resolution{
          arguments: %{
            input: %{
              id: 1,
              users: [
                %{
                  id: 2,
                  post: %{
                    body: "body"
                  }
                }
              ]
            }
          },
          state: :resolved,
          value: nil,
          errors: [error_message]
        }

      definition =
        [
          [
            match: {:is_struct, ErrorMessage},
            path: [:input],
            keys: [
              :id,
              users: [
                alias: :users,
                keys: [
                  :id,
                  post: [
                    keys: [
                      :body
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]

      resolution = Middleware.call(resolution, definition: definition)

      assert %Resolution{
        value: %{
          user_errors: []
        }
      } = resolution
    end
  end
end
