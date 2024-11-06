defmodule AbsintheErrorMessage.Support.Schemas.Post do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string

    has_many :comments, AbsintheErrorMessage.Support.Schemas.Comment

    timestamps()
  end

  @required_fields [:title]

  def changeset(model_or_changeset, attrs \\ %{}) do
    model_or_changeset
    |> cast(attrs, @required_fields)
    |> cast_assoc(:comments)
    # |> validate_required(@required_fields)
    |> validate_length(:title, min: 6)
  end
end
