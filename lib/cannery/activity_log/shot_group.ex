defmodule Cannery.ActivityLog.ShotGroup do
  @moduledoc """
  A shot group records a group of ammo shot during a range trip
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.{Accounts.User, Ammo.AmmoGroup, ActivityLog.ShotGroup}
  alias Ecto.{Changeset, UUID}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "shot_groups" do
    field :count, :integer
    field :date, :date
    field :notes, :string

    belongs_to :user, User
    belongs_to :ammo_group, AmmoGroup

    timestamps()
  end

  @type t :: %ShotGroup{
          id: id(),
          count: integer,
          notes: String.t() | nil,
          date: Date.t() | nil,
          ammo_group: AmmoGroup.t() | nil,
          ammo_group_id: AmmoGroup.id(),
          user: User.t() | nil,
          user_id: User.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_shot_group :: %ShotGroup{}
  @type id :: UUID.t()

  @doc false
  @spec create_changeset(new_shot_group(), attrs :: map()) :: Changeset.t(new_shot_group())
  def create_changeset(shot_group, attrs) do
    shot_group
    |> cast(attrs, [:count, :notes, :date, :ammo_group_id, :user_id])
    |> validate_number(:count, greater_than: 0)
    |> validate_required([:count, :ammo_group_id, :user_id])
  end

  @doc false
  @spec update_changeset(t() | new_shot_group(), attrs :: map()) ::
          Changeset.t(t() | new_shot_group())
  def update_changeset(shot_group, attrs) do
    shot_group
    |> cast(attrs, [:count, :notes, :date])
    |> validate_number(:count, greater_than: 0)
    |> validate_required([:count])
  end
end
