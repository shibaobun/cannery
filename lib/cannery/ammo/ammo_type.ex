defmodule Cannery.Ammo.AmmoType do
  @moduledoc """
  An ammunition type.

  Contains statistical information about the ammunition.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.Ammo.AmmoType
  alias Ecto.{Changeset, UUID}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ammo_types" do
    field :bullet_type, :string
    field :case_material, :string
    field :desc, :string
    field :manufacturer, :string
    field :name, :string
    field :grain, :integer

    timestamps()
  end

  @type t :: %AmmoType{
          id: id(),
          bullet_type: String.t(),
          case_material: String.t(),
          desc: String.t(),
          manufacturer: String.t(),
          name: String.t(),
          grain: integer(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_ammo_type :: %AmmoType{}
  @type id :: UUID.t()

  @doc false
  @spec changeset(t() | new_ammo_type(), attrs :: map()) :: Changeset.t(t() | new_ammo_type())
  def changeset(ammo_type, attrs) do
    ammo_type
    |> cast(attrs, [:name, :desc, :case_material, :bullet_type, :grain, :manufacturer])
    |> validate_required([:name])
  end
end
