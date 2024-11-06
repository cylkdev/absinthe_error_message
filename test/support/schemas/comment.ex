defmodule AbsintheErrorMessage.Support.Schemas.Comment do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :body, :string

    belongs_to :post, AbsintheErrorMessage.Support.Schemas.Post

    timestamps()
  end

  @required_fields [:body]

  def changeset(model_or_changeset, attrs \\ %{}) do
    model_or_changeset
    |> cast(attrs, @required_fields)
    |> cast_assoc(:post)
    # |> validate_required(@required_fields)
    |> validate_length(:body, min: 6)
  end
end
