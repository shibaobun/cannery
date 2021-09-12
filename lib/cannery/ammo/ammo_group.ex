defmodule Cannery.Ammo.AmmoGroup do
  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.{Accounts, Ammo, Containers, Tags}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ammo_groups" do
    field :count, :integer
    field :notes, :string
    field :price_paid, :float

    belongs_to :tag, Tags.Tag
    belongs_to :ammo_type, Ammo.AmmoType
    belongs_to :container, Containers.Container
    belongs_to :user, Accounts.User

    timestamps()
  end

  @doc false
  def changeset(ammo_group, attrs) do
    ammo_group
    |> cast(attrs, [:count, :price_paid, :notes, :tag_id, :ammo_type_id, :container_id, :user_id])
    |> validate_required([
      :count,
      :price_paid,
      :notes,
      :tag_id,
      :ammo_type_id,
      :container_id,
      :user_id
    ])
  end
end
