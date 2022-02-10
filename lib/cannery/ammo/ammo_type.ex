defmodule Cannery.Ammo.AmmoType do
  @moduledoc """
  An ammunition type.

  Contains statistical information about the ammunition.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.Accounts.User
  alias Cannery.Ammo.{AmmoGroup, AmmoType}
  alias Ecto.{Changeset, UUID}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ammo_types" do
    field :name, :string
    field :desc, :string

    # https://en.wikipedia.org/wiki/Bullet#Abbreviations
    field :bullet_type, :string
    field :bullet_core, :string
    field :cartridge, :string
    field :caliber, :string
    field :case_material, :string
    field :grains, :integer
    field :pressure, :string
    field :primer_type, :string
    field :rimfire, :boolean, null: false, default: false
    field :tracer, :boolean, null: false, default: false
    field :incendiary, :boolean, null: false, default: false
    field :blank, :boolean, null: false, default: false
    field :corrosive, :boolean, null: false, default: false

    field :manufacturer, :string
    field :sku, :string

    belongs_to :user, User

    has_many :ammo_groups, AmmoGroup

    timestamps()
  end

  @type t :: %AmmoType{
          id: id(),
          name: String.t(),
          desc: String.t() | nil,
          bullet_type: String.t() | nil,
          bullet_core: String.t() | nil,
          cartridge: String.t() | nil,
          caliber: String.t() | nil,
          case_material: String.t() | nil,
          grains: integer() | nil,
          pressure: String.t() | nil,
          primer_type: String.t() | nil,
          rimfire: boolean(),
          tracer: boolean(),
          incendiary: boolean(),
          blank: boolean(),
          corrosive: boolean(),
          manufacturer: String.t() | nil,
          sku: String.t() | nil,
          user_id: User.id(),
          user: User.t() | nil,
          ammo_groups: [AmmoGroup.t()] | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_ammo_type :: %AmmoType{}
  @type id :: UUID.t()

  @spec changeset_fields() :: [atom()]
  defp changeset_fields,
    do: [
      :name,
      :desc,
      :bullet_type,
      :bullet_core,
      :cartridge,
      :caliber,
      :case_material,
      :grains,
      :pressure,
      :primer_type,
      :rimfire,
      :tracer,
      :incendiary,
      :blank,
      :corrosive,
      :manufacturer,
      :sku
    ]

  @doc false
  @spec create_changeset(t() | new_ammo_type(), attrs :: map()) ::
          Changeset.t(t() | new_ammo_type())
  def create_changeset(ammo_type, attrs) do
    ammo_type
    |> cast(attrs, [:user_id | changeset_fields()])
    |> validate_required([:name, :user_id])
  end

  @doc false
  @spec update_changeset(t() | new_ammo_type(), attrs :: map()) ::
          Changeset.t(t() | new_ammo_type())
  def update_changeset(ammo_type, attrs) do
    ammo_type
    |> cast(attrs, changeset_fields())
    |> validate_required([:name, :user_id])
  end
end
