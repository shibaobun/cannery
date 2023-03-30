defmodule Cannery.ActivityLog.ShotGroup do
  @moduledoc """
  A shot group records a group of ammo shot during a range trip
  """

  use Ecto.Schema
  import CanneryWeb.Gettext
  import Ecto.Changeset
  alias Cannery.{Accounts.User, Ammo, Ammo.Pack}
  alias Ecto.{Changeset, UUID}

  @derive {Jason.Encoder,
           only: [
             :id,
             :count,
             :date,
             :notes,
             :pack_id
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "shot_groups" do
    field :count, :integer
    field :date, :date
    field :notes, :string

    field :user_id, :binary_id
    field :pack_id, :binary_id

    timestamps()
  end

  @type t :: %__MODULE__{
          id: id(),
          count: integer,
          notes: String.t() | nil,
          date: Date.t() | nil,
          pack_id: Pack.id(),
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
          Pack.t() | any(),
          attrs :: map()
        ) :: changeset()
  def create_changeset(
        shot_group,
        %User{id: user_id},
        %Pack{id: pack_id, user_id: user_id} = pack,
        attrs
      ) do
    shot_group
    |> change(user_id: user_id)
    |> change(pack_id: pack_id)
    |> cast(attrs, [:count, :notes, :date])
    |> validate_length(:notes, max: 255)
    |> validate_create_shot_group_count(pack)
    |> validate_required([:date, :pack_id, :user_id])
  end

  def create_changeset(shot_group, _invalid_user, _invalid_pack, attrs) do
    shot_group
    |> cast(attrs, [:count, :notes, :date])
    |> validate_length(:notes, max: 255)
    |> validate_required([:pack_id, :user_id])
    |> add_error(:invalid, dgettext("errors", "Please select a valid user and ammo pack"))
  end

  defp validate_create_shot_group_count(changeset, %Pack{count: pack_count}) do
    case changeset |> Changeset.get_field(:count) do
      nil ->
        changeset |> Changeset.add_error(:ammo_left, dgettext("errors", "can't be blank"))

      count when count > pack_count ->
        changeset
        |> Changeset.add_error(:ammo_left, dgettext("errors", "Ammo left must be at least 0"))

      count when count <= 0 ->
        error =
          dgettext("errors", "Ammo left can be at most %{count} rounds", count: pack_count - 1)

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
    |> validate_length(:notes, max: 255)
    |> validate_number(:count, greater_than: 0)
    |> validate_required([:count, :date])
    |> validate_update_shot_group_count(shot_group, user)
  end

  defp validate_update_shot_group_count(
         changeset,
         %__MODULE__{pack_id: pack_id, count: count},
         user
       ) do
    %{count: pack_count} = Ammo.get_pack!(pack_id, user)

    new_shot_group_count = changeset |> Changeset.get_field(:count)
    shot_diff_to_add = new_shot_group_count - count

    if shot_diff_to_add > pack_count do
      error = dgettext("errors", "Count can be at most %{count} shots", count: pack_count + count)

      changeset |> Changeset.add_error(:count, error)
    else
      changeset
    end
  end
end
