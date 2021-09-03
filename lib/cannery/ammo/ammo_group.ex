defmodule Cannery.Ammo.AmmoGroup do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ammo_groups" do
    field :count, :integer
    field :notes, :string
    field :price_paid, :float
    field :tag_id, :binary_id
    field :ammo_type_id, :binary_id
    field :container_id, :binary_id
    field :user_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(ammo_group, attrs) do
    ammo_group
    |> cast(attrs, [:count, :price_paid, :notes])
    |> validate_required([:count, :price_paid, :notes])
  end
end
