defmodule Cannery.Ammo.Type do
  @moduledoc """
  An ammunition type.

  Contains statistical information about the ammunition.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.Accounts.User
  alias Cannery.Ammo.Pack
  alias Ecto.{Changeset, UUID}

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :desc,
             :bullet_type,
             :bullet_core,
             :cartridge,
             :caliber,
             :case_material,
             :jacket_type,
             :muzzle_velocity,
             :powder_type,
             :powder_grains_per_charge,
             :grains,
             :pressure,
             :primer_type,
             :firing_type,
             :tracer,
             :incendiary,
             :blank,
             :corrosive,
             :manufacturer,
             :upc
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "types" do
    field :name, :string
    field :desc, :string

    field :class, Ecto.Enum, values: [:rifle, :shotgun, :pistol]

    # common fields
    # https://shootersreference.com/reloadingdata/bullet_abbreviations/
    field :bullet_type, :string
    field :bullet_core, :string
    # also gauge for shotguns
    field :caliber, :string
    field :case_material, :string
    field :powder_type, :string
    field :grains, :integer
    field :pressure, :string
    field :primer_type, :string
    field :firing_type, :string
    field :manufacturer, :string
    field :upc, :string

    field :tracer, :boolean, default: false
    field :incendiary, :boolean, default: false
    field :blank, :boolean, default: false
    field :corrosive, :boolean, default: false

    # rifle/pistol fields
    field :cartridge, :string
    field :jacket_type, :string
    field :powder_grains_per_charge, :integer
    field :muzzle_velocity, :integer

    # shotgun fields
    field :wadding, :string
    field :shot_type, :string
    field :shot_material, :string
    field :shot_size, :string
    field :unfired_length, :string
    field :brass_height, :string
    field :chamber_size, :string
    field :load_grains, :integer
    field :shot_charge_weight, :string
    field :dram_equivalent, :string

    field :user_id, :binary_id
    has_many :packs, Pack

    timestamps()
  end

  @type t :: %__MODULE__{
          id: id(),
          name: String.t(),
          desc: String.t() | nil,
          class: class(),
          bullet_type: String.t() | nil,
          bullet_core: String.t() | nil,
          cartridge: String.t() | nil,
          caliber: String.t() | nil,
          case_material: String.t() | nil,
          jacket_type: String.t() | nil,
          muzzle_velocity: integer() | nil,
          powder_type: String.t() | nil,
          powder_grains_per_charge: integer() | nil,
          grains: integer() | nil,
          pressure: String.t() | nil,
          primer_type: String.t() | nil,
          firing_type: String.t() | nil,
          wadding: String.t() | nil,
          shot_type: String.t() | nil,
          shot_material: String.t() | nil,
          shot_size: String.t() | nil,
          unfired_length: String.t() | nil,
          brass_height: String.t() | nil,
          chamber_size: String.t() | nil,
          load_grains: integer() | nil,
          shot_charge_weight: String.t() | nil,
          dram_equivalent: String.t() | nil,
          tracer: boolean(),
          incendiary: boolean(),
          blank: boolean(),
          corrosive: boolean(),
          manufacturer: String.t() | nil,
          upc: String.t() | nil,
          user_id: User.id(),
          packs: [Pack.t()] | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_type :: %__MODULE__{}
  @type id :: UUID.t()
  @type changeset :: Changeset.t(t() | new_type())
  @type class :: :rifle | :shotgun | :pistol | nil

  @spec changeset_fields() :: [atom()]
  defp changeset_fields,
    do: [
      :name,
      :desc,
      :class,
      :bullet_type,
      :bullet_core,
      :cartridge,
      :caliber,
      :case_material,
      :jacket_type,
      :muzzle_velocity,
      :powder_type,
      :powder_grains_per_charge,
      :grains,
      :pressure,
      :primer_type,
      :firing_type,
      :wadding,
      :shot_type,
      :shot_material,
      :shot_size,
      :unfired_length,
      :brass_height,
      :chamber_size,
      :load_grains,
      :shot_charge_weight,
      :dram_equivalent,
      :tracer,
      :incendiary,
      :blank,
      :corrosive,
      :manufacturer,
      :upc
    ]

  @spec string_fields() :: [atom()]
  defp string_fields,
    do: [
      :name,
      :bullet_type,
      :bullet_core,
      :cartridge,
      :caliber,
      :case_material,
      :jacket_type,
      :powder_type,
      :pressure,
      :primer_type,
      :firing_type,
      :wadding,
      :shot_type,
      :shot_material,
      :shot_size,
      :unfired_length,
      :brass_height,
      :chamber_size,
      :shot_charge_weight,
      :dram_equivalent,
      :manufacturer,
      :upc
    ]

  @doc false
  @spec create_changeset(new_type(), User.t(), attrs :: map()) :: changeset()
  def create_changeset(type, %User{id: user_id}, attrs) do
    changeset =
      type
      |> change(user_id: user_id)
      |> cast(attrs, changeset_fields())

    string_fields()
    |> Enum.reduce(changeset, fn field, acc -> acc |> validate_length(field, max: 255) end)
    |> validate_required([:name, :user_id])
  end

  @doc false
  @spec update_changeset(t() | new_type(), attrs :: map()) :: changeset()
  def update_changeset(type, attrs) do
    changeset =
      type
      |> cast(attrs, changeset_fields())

    string_fields()
    |> Enum.reduce(changeset, fn field, acc -> acc |> validate_length(field, max: 255) end)
    |> validate_required(:name)
  end
end
