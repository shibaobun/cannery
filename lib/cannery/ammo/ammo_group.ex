defmodule Cannery.Ammo.AmmoGroup do
  @moduledoc """
  A group of a certain ammunition type.

  Can be placed in a container, and contains auxiliary information such as the
  amount paid for that ammunition, or what condition it is in
  """

  use Ecto.Schema
  import CanneryWeb.Gettext
  import Ecto.Changeset
  alias Cannery.Ammo.{AmmoGroup, AmmoType}
  alias Cannery.{Accounts.User, ActivityLog.ShotGroup, Containers.Container}
  alias Ecto.{Changeset, UUID}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ammo_groups" do
    field :count, :integer
    field :notes, :string
    field :price_paid, :float
    field :staged, :boolean, default: false

    belongs_to :ammo_type, AmmoType
    belongs_to :container, Container
    belongs_to :user, User

    has_many :shot_groups, ShotGroup

    timestamps()
  end

  @type t :: %AmmoGroup{
          id: id(),
          count: integer,
          notes: String.t() | nil,
          price_paid: float() | nil,
          staged: boolean(),
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
  @spec create_changeset(
          new_ammo_group(),
          AmmoType.t() | nil,
          Container.t() | nil,
          User.t(),
          attrs :: map()
        ) :: Changeset.t(new_ammo_group())
  def create_changeset(
        ammo_group,
        %AmmoType{id: ammo_type_id},
        %Container{id: container_id, user_id: user_id},
        %User{id: user_id},
        attrs
      )
      when not (ammo_type_id |> is_nil()) and not (container_id |> is_nil()) and
             not (user_id |> is_nil()) do
    ammo_group
    |> change(ammo_type_id: ammo_type_id)
    |> change(user_id: user_id)
    |> change(container_id: container_id)
    |> cast(attrs, [:count, :price_paid, :notes, :staged])
    |> validate_number(:count, greater_than: 0)
    |> validate_required([:count, :staged, :ammo_type_id, :container_id, :user_id])
  end

  @doc """
  Invalid changeset, used to prompt user to select ammo type and container
  """
  def create_changeset(ammo_group, _invalid_ammo_type, _invalid_container, _invalid_user, attrs) do
    ammo_group
    |> cast(attrs, [:ammo_type_id, :container_id])
    |> validate_required([:ammo_type_id, :container_id])
    |> add_error(:invalid, dgettext("errors", "Please select an ammo type and container"))
  end

  @doc false
  @spec update_changeset(t() | new_ammo_group(), attrs :: map()) ::
          Changeset.t(t() | new_ammo_group())
  def update_changeset(ammo_group, attrs) do
    ammo_group
    |> cast(attrs, [:count, :price_paid, :notes, :staged])
    |> validate_number(:count, greater_than_or_equal_to: 0)
    |> validate_required([:count, :staged])
  end

  @doc """
  This range changeset is used when "using up" ammo groups, and allows for
  updating the count to 0
  """
  @spec range_changeset(t() | new_ammo_group(), attrs :: map()) ::
          Changeset.t(t() | new_ammo_group())
  def range_changeset(ammo_group, attrs) do
    ammo_group
    |> cast(attrs, [:count, :staged])
    |> validate_required([:count, :staged])
  end
end
