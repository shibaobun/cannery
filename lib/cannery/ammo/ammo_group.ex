defmodule Cannery.Ammo.AmmoGroup do
  @moduledoc """
  A group of a certain ammunition type.

  Can be placed in a container, and contains auxiliary information such as the
  amount paid for that ammunition, or what condition it is in
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.Ammo.{AmmoGroup, AmmoType}
  alias Cannery.{Accounts.User, Containers.Container}
  alias Ecto.{Changeset, UUID}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ammo_groups" do
    field :count, :integer
    field :notes, :string
    field :price_paid, :float

    belongs_to :ammo_type, AmmoType
    belongs_to :container, Container
    belongs_to :user, User

    timestamps()
  end

  @type t :: %AmmoGroup{
          id: id(),
          count: integer,
          notes: String.t() | nil,
          price_paid: float() | nil,
          ammo_type: AmmoType.t() | nil,
          ammo_type_id: AmmoType.id(),
          container: Container.t() | nil,
          container_id: Container.id(),
          user: User.t() | nil,
          user_id: User.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_ammo_group :: %AmmoGroup{}
  @type id :: UUID.t()

  @doc false
  @spec create_changeset(new_ammo_group(), attrs :: map()) :: Changeset.t(new_ammo_group())
  def create_changeset(ammo_group, attrs) do
    ammo_group
    |> cast(attrs, [:count, :price_paid, :notes, :ammo_type_id, :container_id, :user_id])
    |> validate_number(:count, greater_than: 0)
    |> validate_required([:count, :ammo_type_id, :container_id, :user_id])
  end

  @doc false
  @spec update_changeset(t() | new_ammo_group(), attrs :: map()) ::
          Changeset.t(t() | new_ammo_group())
  def update_changeset(ammo_group, attrs) do
    ammo_group
    |> cast(attrs, [:count, :price_paid, :notes, :ammo_type_id, :container_id])
    |> validate_number(:count, greater_than: 0)
    |> validate_required([:count, :ammo_type_id, :container_id, :user_id])
  end

  @doc """
  This range changeset is used when "using up" ammo groups, and allows for
  updating the count to 0
  """
  @spec range_changeset(t() | new_ammo_group(), attrs :: map()) ::
          Changeset.t(t() | new_ammo_group())
  def range_changeset(ammo_group, attrs) do
    ammo_group
    |> cast(attrs, [:count])
    |> validate_required([:count, :ammo_type_id, :container_id, :user_id])
  end
end
