# AbsintheErrorMessage

GraphQL spec compliant error messages for absinthe.

In GraphQL, "field-level" and "top-level" messages refer to where and how data or error messages are returned in a query response.

### Top-Level Message

A top-level message is typically associated with the overall status of the GraphQL query or mutation operation.
These messages usually appear in the root-level fields of the GraphQL response, such as the data or errors field.

Example: If there's an error with the entire query (like a syntax error), it would appear in the errors array at
the top level of the response.

```json
{
  "errors": [
    {
      "message": "Cannot query field 'username' on type 'User'.",
      "extensions": %{
        "code": "BAD_REQUEST",
        "field": ["id"],
        "requestId": "request_id"
      },
      "locations": [
        {
          "line": 2,
          "column": 5
        }
      ]
    }
  ]
}
```

###  Field-Level Message

A field-level message is associated with a specific field within the GraphQL operation.
This message typically relates to the resolution or validation of a particular field in a query or mutation.

Example: If a field has an issue, like a field-specific validation error, the error would appear in the errors
array but would reference a specific field within the operation.

In a mutation the field-level message appears on the payload

```json
{
  "data": {
    "user": null,
    "userErrors": [
      %{
        "field": ["input", "id"],
        "message": "not a string representation of an integer"
      }
    ]
  }
}
```

In a query the field-level message appears as in the errors array at the top level of the response.

```json
{
  "data": null,
  "errors": [
    %{
      "message": "not a string representation of an integer",
      "extensions": %{
        "code": "BAD_REQUEST",
        "field": ["id"],
        "requestId": "request_id"
      }
    }
  ]
}
```

In summary Top-level messages pertain to the entire operation, while field-level messages pertain to specific fields within the operation. Top-level messages are found directly within the root errors array, while field-level messages can also reference specific paths (fields) in the GraphQL schema.

### References

* [GraphQL Spec](https://spec.graphql.org/)
* [GraphQL Response Format Documentation](https://spec.graphql.org/October2021/#sec-Response-Format)
* [Apollo Error Handling](https://www.apollographql.com/blog/full-stack-error-handling-with-graphql-apollo)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `error_message` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:error_message, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/error_message>.

