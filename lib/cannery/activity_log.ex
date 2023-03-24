defmodule Cannery.ActivityLog do
  @moduledoc """
  The ActivityLog context.
  """

  import Ecto.Query, warn: false
  alias Cannery.Ammo.{AmmoGroup, AmmoType}
  alias Cannery.{Accounts.User, ActivityLog.ShotGroup, Repo}
  alias Ecto.{Multi, Queryable}

  @doc """
  Returns the list of shot_groups.

  ## Examples

      iex> list_shot_groups(:all, %User{id: 123})
      [%ShotGroup{}, ...]

      iex> list_shot_groups("cool", :all, %User{id: 123})
      [%ShotGroup{notes: "My cool shot group"}, ...]

      iex> list_shot_groups("cool", :rifle, %User{id: 123})
      [%ShotGroup{notes: "Shot some rifle rounds"}, ...]

  """
  @spec list_shot_groups(AmmoType.type() | :all, User.t()) :: [ShotGroup.t()]
  @spec list_shot_groups(search :: nil | String.t(), AmmoType.type() | :all, User.t()) ::
          [ShotGroup.t()]
  def list_shot_groups(search \\ nil, type, %{id: user_id}) do
    from(sg in ShotGroup,
      as: :sg,
      left_join: ag in AmmoGroup,
      as: :ag,
      on: sg.ammo_group_id == ag.id,
      left_join: at in AmmoType,
      as: :at,
      on: ag.ammo_type_id == at.id,
      where: sg.user_id == ^user_id,
      distinct: sg.id
    )
    |> list_shot_groups_search(search)
    |> list_shot_groups_filter_type(type)
    |> Repo.all()
  end

  @spec list_shot_groups_search(Queryable.t(), search :: String.t() | nil) ::
          Queryable.t()
  defp list_shot_groups_search(query, search) when search in ["", nil], do: query

  defp list_shot_groups_search(query, search) when search |> is_binary() do
    trimmed_search = String.trim(search)

    query
    |> where(
      [sg: sg, ag: ag, at: at],
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
        )
    )
    |> order_by([sg: sg], {
      :desc,
      fragment(
        "ts_rank_cd(?, websearch_to_tsquery('english', ?), 4)",
        sg.search,
        ^trimmed_search
      )
    })
  end

  @spec list_shot_groups_filter_type(Queryable.t(), AmmoType.type() | :all) ::
          Queryable.t()
  defp list_shot_groups_filter_type(query, :rifle),
    do: query |> where([at: at], at.type == :rifle)

  defp list_shot_groups_filter_type(query, :pistol),
    do: query |> where([at: at], at.type == :pistol)

  defp list_shot_groups_filter_type(query, :shotgun),
    do: query |> where([at: at], at.type == :shotgun)

  defp list_shot_groups_filter_type(query, _all), do: query

  @spec list_shot_groups_for_ammo_group(AmmoGroup.t(), User.t()) :: [ShotGroup.t()]
  def list_shot_groups_for_ammo_group(
        %AmmoGroup{id: ammo_group_id, user_id: user_id},
        %User{id: user_id}
      ) do
    Repo.all(
      from sg in ShotGroup,
        where: sg.ammo_group_id == ^ammo_group_id,
        where: sg.user_id == ^user_id
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
      fn _repo, %{create_shot_group: %{ammo_group_id: ammo_group_id, user_id: user_id}} ->
        ammo_group =
          Repo.one(
            from ag in AmmoGroup,
              where: ag.id == ^ammo_group_id,
              where: ag.user_id == ^user_id
          )

        {:ok, ammo_group}
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

  @doc """
  Returns the number of shot rounds for an ammo group
  """
  @spec get_used_count(AmmoGroup.t(), User.t()) :: non_neg_integer()
  def get_used_count(%AmmoGroup{id: ammo_group_id} = ammo_group, user) do
    [ammo_group]
    |> get_used_counts(user)
    |> Map.get(ammo_group_id, 0)
  end

  @doc """
  Returns the number of shot rounds for multiple ammo groups
  """
  @spec get_used_counts([AmmoGroup.t()], User.t()) ::
          %{optional(AmmoGroup.id()) => non_neg_integer()}
  def get_used_counts(ammo_groups, %User{id: user_id}) do
    ammo_group_ids =
      ammo_groups
      |> Enum.map(fn %{id: ammo_group_id} -> ammo_group_id end)

    Repo.all(
      from sg in ShotGroup,
        where: sg.ammo_group_id in ^ammo_group_ids,
        where: sg.user_id == ^user_id,
        group_by: sg.ammo_group_id,
        select: {sg.ammo_group_id, sum(sg.count)}
    )
    |> Map.new()
  end

  @doc """
  Returns the last entered shot group date for an ammo group
  """
  @spec get_last_used_date(AmmoGroup.t(), User.t()) :: Date.t() | nil
  def get_last_used_date(%AmmoGroup{id: ammo_group_id} = ammo_group, user) do
    [ammo_group]
    |> get_last_used_dates(user)
    |> Map.get(ammo_group_id)
  end

  @doc """
  Returns the last entered shot group date for an ammo group
  """
  @spec get_last_used_dates([AmmoGroup.t()], User.t()) :: %{optional(AmmoGroup.id()) => Date.t()}
  def get_last_used_dates(ammo_groups, %User{id: user_id}) do
    ammo_group_ids =
      ammo_groups
      |> Enum.map(fn %AmmoGroup{id: ammo_group_id, user_id: ^user_id} -> ammo_group_id end)

    Repo.all(
      from sg in ShotGroup,
        where: sg.ammo_group_id in ^ammo_group_ids,
        where: sg.user_id == ^user_id,
        group_by: sg.ammo_group_id,
        select: {sg.ammo_group_id, max(sg.date)}
    )
    |> Map.new()
  end

  @doc """
  Gets the total number of rounds shot for an ammo type

  Raises `Ecto.NoResultsError` if the Ammo type does not exist.

  ## Examples

      iex> get_used_count_for_ammo_type(123, %User{id: 123})
      35

      iex> get_used_count_for_ammo_type(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_used_count_for_ammo_type(AmmoType.t(), User.t()) :: non_neg_integer()
  def get_used_count_for_ammo_type(%AmmoType{id: ammo_type_id} = ammo_type, user) do
    [ammo_type]
    |> get_used_count_for_ammo_types(user)
    |> Map.get(ammo_type_id, 0)
  end

  @doc """
  Gets the total number of rounds shot for multiple ammo types

  ## Examples

      iex> get_used_count_for_ammo_types(123, %User{id: 123})
      35

  """
  @spec get_used_count_for_ammo_types([AmmoType.t()], User.t()) ::
          %{optional(AmmoType.id()) => non_neg_integer()}
  def get_used_count_for_ammo_types(ammo_types, %User{id: user_id}) do
    ammo_type_ids =
      ammo_types
      |> Enum.map(fn %AmmoType{id: ammo_type_id, user_id: ^user_id} -> ammo_type_id end)

    Repo.all(
      from ag in AmmoGroup,
        left_join: sg in ShotGroup,
        on: ag.id == sg.ammo_group_id,
        where: ag.ammo_type_id in ^ammo_type_ids,
        where: not (sg.count |> is_nil()),
        group_by: ag.ammo_type_id,
        select: {ag.ammo_type_id, sum(sg.count)}
    )
    |> Map.new()
  end
end
