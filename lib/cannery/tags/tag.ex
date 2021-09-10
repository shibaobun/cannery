defmodule Cannery.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tags" do
    field :bg_color, :string
    field :name, :string
    field :text_color, :string
    field :user_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :bg_color, :text_color])
    |> validate_required([:name, :bg_color, :text_color])
  end
end
