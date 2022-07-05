defmodule Cannery.ActivityLog.ShotGroup do
  @moduledoc """
  A shot group records a group of ammo shot during a range trip
  """

  use Ecto.Schema
  import CanneryWeb.Gettext
  import Ecto.Changeset
  alias Cannery.{Accounts.User, ActivityLog.ShotGroup, Ammo.AmmoGroup, Repo}
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
  @spec create_changeset(
          new_shot_group(),
          User.t() | any(),
          AmmoGroup.t() | any(),
          attrs :: map()
        ) ::
          Changeset.t(new_shot_group())
  def create_changeset(
        shot_group,
        %User{id: user_id},
        %AmmoGroup{id: ammo_group_id, user_id: user_id} = ammo_group,
        attrs
      )
      when not (user_id |> is_nil()) and not (ammo_group_id |> is_nil()) do
    shot_group
    |> change(user_id: user_id)
    |> change(ammo_group_id: ammo_group_id)
    |> cast(attrs, [:count, :notes, :date])
    |> validate_number(:count, greater_than: 0)
    |> validate_create_shot_group_count(ammo_group)
    |> validate_required([:count, :ammo_group_id, :user_id])
  end

  def create_changeset(shot_group, _invalid_user, _invalid_ammo_group, attrs) do
    shot_group
    |> cast(attrs, [:count, :notes, :date])
    |> validate_number(:count, greater_than: 0)
    |> validate_required([:count, :ammo_group_id, :user_id])
    |> add_error(:invalid, dgettext("errors", "Please select a valid user and ammo group"))
  end

  defp validate_create_shot_group_count(changeset, %AmmoGroup{count: ammo_group_count}) do
    if changeset |> Changeset.get_field(:count) > ammo_group_count do
      error = dgettext("errors", "Count must be less than %{count}", count: ammo_group_count)
      changeset |> Changeset.add_error(:count, error)
    else
      changeset
    end
  end

  @doc false
  @spec update_changeset(t() | new_shot_group(), User.t(), attrs :: map()) ::
          Changeset.t(t() | new_shot_group())
  def update_changeset(
        %ShotGroup{user_id: user_id} = shot_group,
        %User{id: user_id} = user,
        attrs
      )
      when not (user_id |> is_nil()) do
    shot_group
    |> cast(attrs, [:count, :notes, :date])
    |> validate_number(:count, greater_than: 0)
    |> validate_required([:count])
    |> validate_update_shot_group_count(shot_group, user)
  end

  defp validate_update_shot_group_count(
         changeset,
         %ShotGroup{count: count} = shot_group,
         %User{id: user_id}
       )
       when not (user_id |> is_nil()) do
    %{ammo_group: %AmmoGroup{count: ammo_group_count, user_id: ^user_id}} =
      shot_group |> Repo.preload(:ammo_group)

    new_shot_group_count = changeset |> Changeset.get_field(:count)
    shot_diff_to_add = new_shot_group_count - count

    cond do
      shot_diff_to_add > ammo_group_count ->
        error = dgettext("errors", "Count must be less than %{count}", count: ammo_group_count)
        changeset |> Changeset.add_error(:count, error)

      new_shot_group_count <= 0 ->
        changeset |> Changeset.add_error(:count, dgettext("errors", "Count must be at least 1"))

      true ->
        changeset
    end
  end
end
