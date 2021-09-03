defmodule Cannery.Ammo.AmmoType do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ammo_types" do
    field :bullet_type, :string
    field :case_material, :string
    field :desc, :string
    field :manufacturer, :string
    field :name, :string
    field :weight, :float

    timestamps()
  end

  @doc false
  def changeset(ammo_type, attrs) do
    ammo_type
    |> cast(attrs, [:name, :desc, :case_material, :bullet_type, :weight, :manufacturer])
    |> validate_required([:name, :desc, :case_material, :bullet_type, :weight, :manufacturer])
  end
end
