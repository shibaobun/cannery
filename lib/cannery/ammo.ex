defmodule Cannery.Ammo do
  @moduledoc """
  The Ammo context.
  """

  import CanneryWeb.Gettext
  import Ecto.Query, warn: false
  alias Cannery.{Accounts.User, Containers, Repo}
  alias Cannery.ActivityLog.ShotGroup
  alias Cannery.Ammo.{AmmoGroup, AmmoType}
  alias Ecto.Changeset

  @ammo_group_create_limit 10_000

  @doc """
  Returns the list of ammo_types.

  ## Examples

      iex> list_ammo_types(%User{id: 123})
      [%AmmoType{}, ...]

  """
  @spec list_ammo_types(User.t()) :: [AmmoType.t()]
  def list_ammo_types(%User{id: user_id}),
    do: Repo.all(from at in AmmoType, where: at.user_id == ^user_id, order_by: at.name)

  @doc """
  Returns a count of ammo_types.

  ## Examples

      iex> get_ammo_types_count!(%User{id: 123})
      3

  """
  @spec get_ammo_types_count!(User.t()) :: integer()
  def get_ammo_types_count!(%User{id: user_id}) do
    Repo.one(
      from at in AmmoType,
        where: at.user_id == ^user_id,
        select: count(at.id),
        distinct: true
    )
  end

  @doc """
  Gets a single ammo_type.

  Raises `Ecto.NoResultsError` if the Ammo type does not exist.

  ## Examples

      iex> get_ammo_type!(123, %User{id: 123})
      %AmmoType{}

      iex> get_ammo_type!(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_ammo_type!(AmmoType.id(), User.t()) :: AmmoType.t()
  def get_ammo_type!(id, %User{id: user_id}),
    do: Repo.one!(from at in AmmoType, where: at.id == ^id and at.user_id == ^user_id)

  @doc """
  Gets the average cost of a single ammo type

  ## Examples

      iex> get_average_cost_for_ammo_type!(%AmmoType{id: 123}, %User{id: 123})
      1.50

  """
  @spec get_average_cost_for_ammo_type!(AmmoType.t(), User.t()) :: float() | nil
  def get_average_cost_for_ammo_type!(
        %AmmoType{id: ammo_type_id, user_id: user_id},
        %User{id: user_id}
      ) do
    sg_total_query =
      from sg in ShotGroup,
        where: not (sg.count |> is_nil()),
        group_by: sg.ammo_group_id,
        select: %{ammo_group_id: sg.ammo_group_id, total: sum(sg.count)}

    Repo.one!(
      from ag in AmmoGroup,
        as: :ammo_group,
        left_join: sg_query in subquery(sg_total_query),
        on: ag.id == sg_query.ammo_group_id,
        where: ag.ammo_type_id == ^ammo_type_id,
        where: not (ag.price_paid |> is_nil()),
        select: sum(ag.price_paid) / sum(ag.count + coalesce(sg_query.total, 0))
    )
  end

  @doc """
  Gets the total number of rounds for an ammo type

  Raises `Ecto.NoResultsError` if the Ammo type does not exist.

  ## Examples

      iex> get_round_count_for_ammo_type(123, %User{id: 123})
      %AmmoType{}

      iex> get_round_count_for_ammo_type(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_round_count_for_ammo_type(AmmoType.t(), User.t()) :: non_neg_integer()
  def get_round_count_for_ammo_type(
        %AmmoType{id: ammo_type_id, user_id: user_id},
        %User{id: user_id}
      ) do
    Repo.one!(
      from ag in AmmoGroup,
        where: ag.ammo_type_id == ^ammo_type_id,
        select: sum(ag.count)
    ) || 0
  end

  @doc """
  Gets the total number of rounds shot for an ammo type

  Raises `Ecto.NoResultsError` if the Ammo type does not exist.

  ## Examples

      iex> get_used_count_for_ammo_type(123, %User{id: 123})
      %AmmoType{}

      iex> get_used_count_for_ammo_type(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_used_count_for_ammo_type(AmmoType.t(), User.t()) :: non_neg_integer()
  def get_used_count_for_ammo_type(
        %AmmoType{id: ammo_type_id, user_id: user_id},
        %User{id: user_id}
      ) do
    Repo.one!(
      from ag in AmmoGroup,
        left_join: sg in assoc(ag, :shot_groups),
        where: ag.ammo_type_id == ^ammo_type_id,
        select: sum(sg.count)
    ) || 0
  end

  @doc """
  Creates a ammo_type.

  ## Examples

      iex> create_ammo_type(%{field: value}, %User{id: 123})
      {:ok, %AmmoType{}}

      iex> create_ammo_type(%{field: bad_value}, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec create_ammo_type(attrs :: map(), User.t()) ::
          {:ok, AmmoType.t()} | {:error, Changeset.t(AmmoType.new_ammo_type())}
  def create_ammo_type(attrs \\ %{}, %User{} = user),
    do: %AmmoType{} |> AmmoType.create_changeset(user, attrs) |> Repo.insert()

  @doc """
  Updates a ammo_type.

  ## Examples

      iex> update_ammo_type(ammo_type, %{field: new_value}, %User{id: 123})
      {:ok, %AmmoType{}}

      iex> update_ammo_type(ammo_type, %{field: bad_value}, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec update_ammo_type(AmmoType.t(), attrs :: map(), User.t()) ::
          {:ok, AmmoType.t()} | {:error, Changeset.t(AmmoType.t())}
  def update_ammo_type(%AmmoType{user_id: user_id} = ammo_type, attrs, %User{id: user_id}),
    do: ammo_type |> AmmoType.update_changeset(attrs) |> Repo.update()

  @doc """
  Deletes a ammo_type.

  ## Examples

      iex> delete_ammo_type(ammo_type, %User{id: 123})
      {:ok, %AmmoType{}}

      iex> delete_ammo_type(ammo_type, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec delete_ammo_type(AmmoType.t(), User.t()) ::
          {:ok, AmmoType.t()} | {:error, Changeset.t(AmmoType.t())}
  def delete_ammo_type(%AmmoType{user_id: user_id} = ammo_type, %User{id: user_id}),
    do: ammo_type |> Repo.delete()

  @doc """
  Deletes a ammo_type.

  ## Examples

      iex> delete_ammo_type(ammo_type, %User{id: 123})
      %AmmoType{}

  """
  @spec delete_ammo_type!(AmmoType.t(), User.t()) :: AmmoType.t()
  def delete_ammo_type!(%AmmoType{user_id: user_id} = ammo_type, %User{id: user_id}),
    do: ammo_type |> Repo.delete!()

  @doc """
  Returns the list of ammo_groups for a user and type.

  ## Examples

      iex> list_ammo_groups_for_type(%AmmoType{id: 123}, %User{id: 123})
      [%AmmoGroup{}, ...]

  """
  @spec list_ammo_groups_for_type(AmmoType.t(), User.t()) :: [AmmoGroup.t()]
  @spec list_ammo_groups_for_type(AmmoType.t(), User.t(), include_empty :: boolean()) ::
          [AmmoGroup.t()]
  def list_ammo_groups_for_type(ammo_type, user, include_empty \\ false)

  def list_ammo_groups_for_type(
        %AmmoType{id: ammo_type_id, user_id: user_id},
        %User{id: user_id},
        _include_empty = true
      ) do
    Repo.all(
      from ag in AmmoGroup,
        left_join: sg in assoc(ag, :shot_groups),
        where: ag.ammo_type_id == ^ammo_type_id,
        where: ag.user_id == ^user_id,
        preload: [shot_groups: sg],
        order_by: ag.id
    )
  end

  def list_ammo_groups_for_type(
        %AmmoType{id: ammo_type_id, user_id: user_id},
        %User{id: user_id},
        _include_empty = false
      ) do
    Repo.all(
      from ag in AmmoGroup,
        left_join: sg in assoc(ag, :shot_groups),
        where: ag.ammo_type_id == ^ammo_type_id,
        where: ag.user_id == ^user_id,
        where: not (ag.count == 0),
        preload: [shot_groups: sg],
        order_by: ag.id
    )
  end

  @doc """
  Returns the count of ammo_groups for an ammo type.

  ## Examples

      iex> get_ammo_groups_count_for_type(%User{id: 123})
      3

  """
  @spec get_ammo_groups_count_for_type(AmmoType.t(), User.t()) :: [AmmoGroup.t()]
  @spec get_ammo_groups_count_for_type(AmmoType.t(), User.t(), include_empty :: boolean()) ::
          [AmmoGroup.t()]
  def get_ammo_groups_count_for_type(ammo_type, user, include_empty \\ false)

  def get_ammo_groups_count_for_type(
        %AmmoType{id: ammo_type_id, user_id: user_id},
        %User{id: user_id},
        _include_empty = true
      ) do
    Repo.one!(
      from ag in AmmoGroup,
        where: ag.user_id == ^user_id,
        where: ag.ammo_type_id == ^ammo_type_id,
        distinct: true,
        select: count(ag.id)
    ) || 0
  end

  def get_ammo_groups_count_for_type(
        %AmmoType{id: ammo_type_id, user_id: user_id},
        %User{id: user_id},
        _include_empty = false
      ) do
    Repo.one!(
      from ag in AmmoGroup,
        where: ag.user_id == ^user_id,
        where: ag.ammo_type_id == ^ammo_type_id,
        where: not (ag.count == 0),
        distinct: true,
        select: count(ag.id)
    ) || 0
  end

  @doc """
  Returns the list of ammo_groups for a user.

  ## Examples

      iex> list_ammo_groups(%User{id: 123})
      [%AmmoGroup{}, ...]

  """
  @spec list_ammo_groups(User.t()) :: [AmmoGroup.t()]
  @spec list_ammo_groups(User.t(), include_empty :: boolean()) :: [AmmoGroup.t()]
  def list_ammo_groups(user, include_empty \\ false)

  def list_ammo_groups(%User{id: user_id}, _include_empty = true) do
    Repo.all(
      from ag in AmmoGroup,
        left_join: sg in assoc(ag, :shot_groups),
        where: ag.user_id == ^user_id,
        preload: [shot_groups: sg],
        order_by: ag.id
    )
  end

  def list_ammo_groups(%User{id: user_id}, _include_empty = false) do
    Repo.all(
      from ag in AmmoGroup,
        left_join: sg in assoc(ag, :shot_groups),
        where: ag.user_id == ^user_id,
        where: not (ag.count == 0),
        preload: [shot_groups: sg],
        order_by: ag.id
    )
  end

  @doc """
  Returns the list of staged ammo_groups for a user.

  ## Examples

      iex> list_staged_ammo_groups(%User{id: 123})
      [%AmmoGroup{}, ...]

  """
  @spec list_staged_ammo_groups(User.t()) :: [AmmoGroup.t()]
  def list_staged_ammo_groups(%User{id: user_id}) do
    Repo.all(
      from ag in AmmoGroup,
        left_join: sg in assoc(ag, :shot_groups),
        where: ag.user_id == ^user_id,
        where: ag.staged == true,
        preload: [shot_groups: sg],
        order_by: ag.id
    )
  end

  @doc """
  Gets a single ammo_group.

  Raises `Ecto.NoResultsError` if the Ammo group does not exist.

  ## Examples

      iex> get_ammo_group!(123, %User{id: 123})
      %AmmoGroup{}

      iex> get_ammo_group!(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_ammo_group!(AmmoGroup.id(), User.t()) :: AmmoGroup.t()
  def get_ammo_group!(id, %User{id: user_id}) do
    Repo.one!(
      from ag in AmmoGroup,
        left_join: sg in assoc(ag, :shot_groups),
        where: ag.id == ^id,
        where: ag.user_id == ^user_id,
        preload: [shot_groups: sg]
    )
  end

  @doc """
  Returns the number of shot rounds for an ammo group
  """
  @spec get_used_count(AmmoGroup.t()) :: non_neg_integer()
  def get_used_count(%AmmoGroup{} = ammo_group) do
    ammo_group
    |> Repo.preload(:shot_groups)
    |> Map.fetch!(:shot_groups)
    |> Enum.map(fn %{count: count} -> count end)
    |> Enum.sum()
  end

  @doc """
  Calculates the percentage remaining of an ammo group out of 100
  """
  @spec get_percentage_remaining(AmmoGroup.t()) :: non_neg_integer()
  def get_percentage_remaining(%AmmoGroup{count: 0}), do: 0

  def get_percentage_remaining(%AmmoGroup{count: count} = ammo_group) do
    ammo_group = ammo_group |> Repo.preload(:shot_groups)

    shot_group_sum =
      ammo_group.shot_groups |> Enum.map(fn %{count: count} -> count end) |> Enum.sum()

    round(count / (count + shot_group_sum) * 100)
  end

  @doc """
  Creates multiple ammo_groups at once.

  ## Examples

      iex> create_ammo_groups(%{field: value}, 3, %User{id: 123})
      {:ok, {3, [%AmmoGroup{}]}}

      iex> create_ammo_groups(%{field: bad_value}, 3, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec create_ammo_groups(attrs :: map(), multiplier :: non_neg_integer(), User.t()) ::
          {:ok, {count :: non_neg_integer(), [AmmoGroup.t()] | nil}}
          | {:error, Changeset.t(AmmoGroup.new_ammo_group())}
  def create_ammo_groups(
        %{"ammo_type_id" => ammo_type_id, "container_id" => container_id} = attrs,
        multiplier,
        %User{} = user
      )
      when multiplier >= 1 and multiplier <= @ammo_group_create_limit and
             not (ammo_type_id |> is_nil()) and not (container_id |> is_nil()) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    changesets =
      Enum.map(1..multiplier, fn _count ->
        %AmmoGroup{}
        |> AmmoGroup.create_changeset(
          get_ammo_type!(ammo_type_id, user),
          Containers.get_container!(container_id, user),
          user,
          attrs
        )
      end)

    if changesets |> Enum.all?(fn %{valid?: valid} -> valid end) do
      {count, inserted_ammo_groups} =
        Repo.insert_all(
          AmmoGroup,
          changesets
          |> Enum.map(fn changeset ->
            changeset
            |> Map.get(:changes)
            |> Map.merge(%{inserted_at: now, updated_at: now})
          end),
          returning: true
        )

      {:ok, {count, inserted_ammo_groups}}
    else
      changesets
      |> Enum.reject(fn %{valid?: valid} -> valid end)
      |> List.first()
      |> Changeset.apply_action(:insert)
    end
  end

  def create_ammo_groups(
        %{"ammo_type_id" => ammo_type_id, "container_id" => container_id} = attrs,
        _multiplier,
        user
      )
      when not (ammo_type_id |> is_nil()) and not (container_id |> is_nil()) do
    changeset =
      %AmmoGroup{}
      |> AmmoGroup.create_changeset(
        get_ammo_type!(ammo_type_id, user),
        Containers.get_container!(container_id, user),
        user,
        attrs
      )
      |> Changeset.add_error(:multiplier, dgettext("errors", "Invalid multiplier"))

    {:error, changeset}
  end

  def create_ammo_groups(invalid_attrs, _multiplier, user) do
    {:error, %AmmoGroup{} |> AmmoGroup.create_changeset(nil, nil, user, invalid_attrs)}
  end

  @doc """
  Updates a ammo_group.

  ## Examples

      iex> update_ammo_group(ammo_group, %{field: new_value}, %User{id: 123})
      {:ok, %AmmoGroup{}}

      iex> update_ammo_group(ammo_group, %{field: bad_value}, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec update_ammo_group(AmmoGroup.t(), attrs :: map(), User.t()) ::
          {:ok, AmmoGroup.t()} | {:error, Changeset.t(AmmoGroup.t())}
  def update_ammo_group(%AmmoGroup{user_id: user_id} = ammo_group, attrs, %User{id: user_id}),
    do: ammo_group |> AmmoGroup.update_changeset(attrs) |> Repo.update()

  @doc """
  Deletes a ammo_group.

  ## Examples

      iex> delete_ammo_group(ammo_group, %User{id: 123})
      {:ok, %AmmoGroup{}}

      iex> delete_ammo_group(ammo_group, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec delete_ammo_group(AmmoGroup.t(), User.t()) ::
          {:ok, AmmoGroup.t()} | {:error, Changeset.t(AmmoGroup.t())}
  def delete_ammo_group(%AmmoGroup{user_id: user_id} = ammo_group, %User{id: user_id}),
    do: ammo_group |> Repo.delete()

  @doc """
  Deletes a ammo_group.

  ## Examples

      iex> delete_ammo_group!(ammo_group, %User{id: 123})
      %AmmoGroup{}

  """
  @spec delete_ammo_group!(AmmoGroup.t(), User.t()) :: AmmoGroup.t()
  def delete_ammo_group!(%AmmoGroup{user_id: user_id} = ammo_group, %User{id: user_id}),
    do: ammo_group |> Repo.delete!()
end
