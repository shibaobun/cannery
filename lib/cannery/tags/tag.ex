defmodule Cannery.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.{Accounts}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tags" do
    field :bg_color, :string
    field :name, :string
    field :text_color, :string

    belongs_to :user, Accounts.User

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :bg_color, :text_color, :user_id])
    |> validate_required([:name, :bg_color, :text_color, :user_id])
  end
end
