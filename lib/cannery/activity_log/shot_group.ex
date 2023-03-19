defmodule Cannery.ActivityLog.ShotGroup do
  @moduledoc """
  A shot group records a group of ammo shot during a range trip
  """

  use Ecto.Schema
  import CanneryWeb.Gettext
  import Ecto.Changeset
  alias Cannery.{Accounts.User, Ammo, Ammo.AmmoGroup}
  alias Ecto.{Changeset, UUID}

  @derive {Jason.Encoder,
           only: [
             :id,
             :count,
             :date,
             :notes,
             :ammo_group_id
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "shot_groups" do
    field :count, :integer
    field :date, :date
    field :notes, :string

    field :user_id, :binary_id
    field :ammo_group_id, :binary_id

    timestamps()
  end

  @type t :: %__MODULE__{
          id: id(),
          count: integer,
          notes: String.t() | nil,
          date: Date.t() | nil,
          ammo_group_id: AmmoGroup.id(),
          user_id: User.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_shot_group :: %__MODULE__{}
  @type id :: UUID.t()
  @type changeset :: Changeset.t(t() | new_shot_group())

  @doc false
  @spec create_changeset(
          new_shot_group(),
          User.t() | any(),
          AmmoGroup.t() | any(),
          attrs :: map()
        ) :: changeset()
  def create_changeset(
        shot_group,
        %User{id: user_id},
        %AmmoGroup{id: ammo_group_id, user_id: user_id} = ammo_group,
        attrs
      ) do
    shot_group
    |> change(user_id: user_id)
    |> change(ammo_group_id: ammo_group_id)
    |> cast(attrs, [:count, :notes, :date])
    |> validate_create_shot_group_count(ammo_group)
    |> validate_required([:date, :ammo_group_id, :user_id])
  end

  def create_changeset(shot_group, _invalid_user, _invalid_ammo_group, attrs) do
    shot_group
    |> cast(attrs, [:count, :notes, :date])
    |> validate_required([:ammo_group_id, :user_id])
    |> add_error(:invalid, dgettext("errors", "Please select a valid user and ammo pack"))
  end

  defp validate_create_shot_group_count(changeset, %AmmoGroup{count: ammo_group_count}) do
    case changeset |> Changeset.get_field(:count) do
      nil ->
        changeset |> Changeset.add_error(:ammo_left, dgettext("errors", "can't be blank"))

      count when count > ammo_group_count ->
        changeset
        |> Changeset.add_error(:ammo_left, dgettext("errors", "Ammo left must be at least 0"))

      count when count <= 0 ->
        error =
          dgettext("errors", "Ammo left can be at most %{count} rounds",
            count: ammo_group_count - 1
          )

        changeset |> Changeset.add_error(:ammo_left, error)

      _valid_count ->
        changeset
    end
  end

  @doc false
  @spec update_changeset(t() | new_shot_group(), User.t(), attrs :: map()) :: changeset()
  def update_changeset(%__MODULE__{} = shot_group, user, attrs) do
    shot_group
    |> cast(attrs, [:count, :notes, :date])
    |> validate_number(:count, greater_than: 0)
    |> validate_required([:count, :date])
    |> validate_update_shot_group_count(shot_group, user)
  end

  defp validate_update_shot_group_count(
         changeset,
         %__MODULE__{ammo_group_id: ammo_group_id, count: count},
         user
       ) do
    %{count: ammo_group_count} = Ammo.get_ammo_group!(ammo_group_id, user)

    new_shot_group_count = changeset |> Changeset.get_field(:count)
    shot_diff_to_add = new_shot_group_count - count

    if shot_diff_to_add > ammo_group_count do
      error =
        dgettext("errors", "Count can be at most %{count} shots", count: ammo_group_count + count)

      changeset |> Changeset.add_error(:count, error)
    else
      changeset
    end
  end
end
