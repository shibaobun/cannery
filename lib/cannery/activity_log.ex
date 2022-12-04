defmodule Cannery.ActivityLog do
  @moduledoc """
  The ActivityLog context.
  """

  import Ecto.Query, warn: false
  alias Cannery.{Accounts.User, ActivityLog.ShotGroup, Ammo.AmmoGroup, Repo}
  alias Ecto.Multi

  @doc """
  Returns the list of shot_groups.

  ## Examples

      iex> list_shot_groups(%User{id: 123})
      [%ShotGroup{}, ...]

      iex> list_shot_groups("cool", %User{id: 123})
      [%ShotGroup{notes: "My cool shot group"}, ...]

  """
  @spec list_shot_groups(User.t()) :: [ShotGroup.t()]
  @spec list_shot_groups(search :: nil | String.t(), User.t()) :: [ShotGroup.t()]
  def list_shot_groups(search \\ nil, user)

  def list_shot_groups(search, %{id: user_id}) when search |> is_nil() or search == "",
    do: Repo.all(from sg in ShotGroup, where: sg.user_id == ^user_id)

  def list_shot_groups(search, %{id: user_id}) when search |> is_binary() do
    trimmed_search = String.trim(search)

    Repo.all(
      from sg in ShotGroup,
        left_join: ag in assoc(sg, :ammo_group),
        left_join: at in assoc(ag, :ammo_type),
        where: sg.user_id == ^user_id,
        where:
          fragment(
            "? @@ websearch_to_tsquery('english', ?)",
            sg.search,
            ^trimmed_search
          ) or
            fragment(
              "? @@ websearch_to_tsquery('english', ?)",
              ag.search,
              ^trimmed_search
            ) or
            fragment(
              "? @@ websearch_to_tsquery('english', ?)",
              at.search,
              ^trimmed_search
            ),
        order_by: {
          :desc,
          fragment(
            "ts_rank_cd(?, websearch_to_tsquery('english', ?), 4)",
            sg.search,
            ^trimmed_search
          )
        }
    )
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
          {:ok, ShotGroup.t()} | {:error, ShotGroup.changeset() | nil}
  def create_shot_group(attrs, user, ammo_group) do
    Multi.new()
    |> Multi.insert(
      :create_shot_group,
      %ShotGroup{} |> ShotGroup.create_changeset(user, ammo_group, attrs)
    )
    |> Multi.run(
      :ammo_group,
      fn repo, %{create_shot_group: %{ammo_group_id: ammo_group_id, user_id: user_id}} ->
        {:ok,
         repo.one(from ag in AmmoGroup, where: ag.id == ^ammo_group_id and ag.user_id == ^user_id)}
      end
    )
    |> Multi.update(
      :update_ammo_group,
      fn %{create_shot_group: %{count: shot_group_count}, ammo_group: %{count: ammo_group_count}} ->
        ammo_group |> AmmoGroup.range_changeset(%{"count" => ammo_group_count - shot_group_count})
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{create_shot_group: shot_group}} -> {:ok, shot_group}
      {:error, :create_shot_group, changeset, _changes_so_far} -> {:error, changeset}
      {:error, _other_transaction, _value, _changes_so_far} -> {:error, nil}
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
          {:ok, ShotGroup.t()} | {:error, ShotGroup.changeset() | nil}
  def update_shot_group(
        %ShotGroup{count: count, user_id: user_id} = shot_group,
        attrs,
        %User{id: user_id} = user
      ) do
    Multi.new()
    |> Multi.update(
      :update_shot_group,
      shot_group |> ShotGroup.update_changeset(user, attrs)
    )
    |> Multi.run(
      :ammo_group,
      fn repo, %{update_shot_group: %{ammo_group_id: ammo_group_id, user_id: user_id}} ->
        {:ok,
         repo.one(from ag in AmmoGroup, where: ag.id == ^ammo_group_id and ag.user_id == ^user_id)}
      end
    )
    |> Multi.update(
      :update_ammo_group,
      fn %{
           update_shot_group: %{count: new_count},
           ammo_group: %{count: ammo_group_count} = ammo_group
         } ->
        shot_diff_to_add = new_count - count
        new_ammo_group_count = ammo_group_count - shot_diff_to_add
        ammo_group |> AmmoGroup.range_changeset(%{"count" => new_ammo_group_count})
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{update_shot_group: shot_group}} -> {:ok, shot_group}
      {:error, :update_shot_group, changeset, _changes_so_far} -> {:error, changeset}
      {:error, _other_transaction, _value, _changes_so_far} -> {:error, nil}
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
          {:ok, ShotGroup.t()} | {:error, ShotGroup.changeset()}
  def delete_shot_group(
        %ShotGroup{user_id: user_id} = shot_group,
        %User{id: user_id}
      ) do
    Multi.new()
    |> Multi.delete(:delete_shot_group, shot_group)
    |> Multi.run(
      :ammo_group,
      fn repo, %{delete_shot_group: %{ammo_group_id: ammo_group_id, user_id: user_id}} ->
        {:ok,
         repo.one(from ag in AmmoGroup, where: ag.id == ^ammo_group_id and ag.user_id == ^user_id)}
      end
    )
    |> Multi.update(
      :update_ammo_group,
      fn %{
           delete_shot_group: %{count: count},
           ammo_group: %{count: ammo_group_count} = ammo_group
         } ->
        new_ammo_group_count = ammo_group_count + count
        ammo_group |> AmmoGroup.range_changeset(%{"count" => new_ammo_group_count})
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_shot_group: shot_group}} -> {:ok, shot_group}
      {:error, :delete_shot_group, changeset, _changes_so_far} -> {:error, changeset}
      {:error, _other_transaction, _value, _changes_so_far} -> {:error, nil}
    end
  end
end
