defmodule Cannery.ActivityLog do
  @moduledoc """
  The ActivityLog context.
  """

  import Ecto.Query, warn: false
  import CanneryWeb.Gettext
  alias Cannery.{Accounts.User, ActivityLog.ShotGroup, Ammo, Ammo.AmmoGroup, Repo}
  alias Ecto.{Changeset, Multi}

  @doc """
  Returns the list of shot_groups.

  ## Examples

      iex> list_shot_groups(%User{id: 123})
      [%ShotGroup{}, ...]

  """
  @spec list_shot_groups(User.t()) :: [ShotGroup.t()]
  def list_shot_groups(%User{id: user_id}) do
    Repo.all(from(sg in ShotGroup, where: sg.user_id == ^user_id))
  end

  @doc """
  Gets a single shot_group.

  Raises `Ecto.NoResultsError` if the Shot group does not exist.

  ## Examples

      iex> get_shot_group!(123, %User{id: 123})
      %ShotGroup{}

      iex> get_shot_group!(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_shot_group!(ShotGroup.id(), User.t()) :: ShotGroup.t()
  def get_shot_group!(id, %User{id: user_id}) do
    Repo.one!(
      from sg in ShotGroup,
        where: sg.id == ^id,
        where: sg.user_id == ^user_id,
        order_by: sg.date
    )
  end

  @doc """
  Creates a shot_group.

  ## Examples

      iex> create_shot_group(%{field: value}, %User{id: 123})
      {:ok, %ShotGroup{}}

      iex> create_shot_group(%{field: bad_value}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_shot_group(attrs :: map(), User.t(), AmmoGroup.t()) ::
          {:ok, ShotGroup.t()} | {:error, Changeset.t(ShotGroup.t()) | nil}
  def create_shot_group(
        attrs,
        %User{id: user_id},
        %AmmoGroup{id: ammo_group_id, count: ammo_group_count, user_id: user_id} = ammo_group
      ) do
    attrs = attrs |> Map.merge(%{"user_id" => user_id, "ammo_group_id" => ammo_group_id})
    changeset = %ShotGroup{} |> ShotGroup.create_changeset(attrs)
    shot_group_count = changeset |> Changeset.get_field(:count)

    if shot_group_count > ammo_group_count do
      error = dgettext("errors", "Count must be less than %{count}", count: ammo_group_count)
      changeset = changeset |> Changeset.add_error(:count, error)
      {:error, changeset}
    else
      Multi.new()
      |> Multi.insert(:create_shot_group, changeset)
      |> Multi.update(
        :update_ammo_group,
        ammo_group |> AmmoGroup.range_changeset(%{"count" => ammo_group_count - shot_group_count})
      )
      |> Repo.transaction()
      |> case do
        {:ok, %{create_shot_group: shot_group}} -> {:ok, shot_group}
        {:error, :create_shot_group, changeset, _changes_so_far} -> {:error, changeset}
        {:error, _other_transaction, _value, _changes_so_far} -> {:error, nil}
      end
    end
  end

  @doc """
  Updates a shot_group.

  ## Examples

      iex> update_shot_group(shot_group, %{field: new_value}, %User{id: 123})
      {:ok, %ShotGroup{}}

      iex> update_shot_group(shot_group, %{field: bad_value}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_shot_group(ShotGroup.t(), attrs :: map(), User.t()) ::
          {:ok, ShotGroup.t()} | {:error, Changeset.t(ShotGroup.t()) | nil}
  def update_shot_group(
        %ShotGroup{count: count, user_id: user_id, ammo_group_id: ammo_group_id} = shot_group,
        attrs,
        %User{id: user_id} = user
      ) do
    %{count: ammo_group_count, user_id: ^user_id} =
      ammo_group = ammo_group_id |> Ammo.get_ammo_group!(user)

    changeset = shot_group |> ShotGroup.update_changeset(attrs)
    new_shot_group_count = changeset |> Changeset.get_field(:count)
    shot_diff_to_add = new_shot_group_count - count

    cond do
      shot_diff_to_add > ammo_group_count ->
        error = dgettext("errors", "Count must be less than %{count}", count: ammo_group_count)
        changeset = changeset |> Changeset.add_error(:count, error)
        {:error, changeset}

      new_shot_group_count <= 0 ->
        error = dgettext("errors", "Count must be at least 1")
        changeset = changeset |> Changeset.add_error(:count, error)
        {:error, changeset}

      true ->
        Multi.new()
        |> Multi.update(:update_shot_group, changeset)
        |> Multi.update(
          :update_ammo_group,
          ammo_group
          |> AmmoGroup.range_changeset(%{"count" => ammo_group_count - shot_diff_to_add})
        )
        |> Repo.transaction()
        |> case do
          {:ok, %{update_shot_group: shot_group}} -> {:ok, shot_group}
          {:error, :update_shot_group, changeset, _changes_so_far} -> {:error, changeset}
          {:error, _other_transaction, _value, _changes_so_far} -> {:error, nil}
        end
    end
  end

  @doc """
  Deletes a shot_group.

  ## Examples

      iex> delete_shot_group(shot_group, %User{id: 123})
      {:ok, %ShotGroup{}}

      iex> delete_shot_group(shot_group, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_shot_group(ShotGroup.t(), User.t()) ::
          {:ok, ShotGroup.t()} | {:error, Changeset.t(ShotGroup.t())}
  def delete_shot_group(
        %ShotGroup{count: count, user_id: user_id, ammo_group_id: ammo_group_id} = shot_group,
        %User{id: user_id} = user
      ) do
    %{count: ammo_group_count, user_id: ^user_id} =
      ammo_group = ammo_group_id |> Ammo.get_ammo_group!(user)

    Multi.new()
    |> Multi.delete(:delete_shot_group, shot_group)
    |> Multi.update(
      :update_ammo_group,
      ammo_group
      |> AmmoGroup.range_changeset(%{"count" => ammo_group_count + count})
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_shot_group: shot_group}} -> {:ok, shot_group}
      {:error, :delete_shot_group, changeset, _changes_so_far} -> {:error, changeset}
      {:error, _other_transaction, _value, _changes_so_far} -> {:error, nil}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking shot_group changes.

  ## Examples

      iex> change_shot_group(shot_group)
      %Ecto.Changeset{data: %ShotGroup{}}

  """
  @spec change_shot_group(ShotGroup.t() | ShotGroup.new_shot_group()) ::
          Changeset.t(ShotGroup.t() | ShotGroup.new_shot_group())
  @spec change_shot_group(ShotGroup.t() | ShotGroup.new_shot_group(), attrs :: map()) ::
          Changeset.t(ShotGroup.t() | ShotGroup.new_shot_group())
  def change_shot_group(%ShotGroup{} = shot_group, attrs \\ %{}) do
    shot_group |> ShotGroup.update_changeset(attrs)
  end
end
