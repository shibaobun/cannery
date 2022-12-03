defmodule Cannery.Ammo do
  @moduledoc """
  The Ammo context.
  """

  import CanneryWeb.Gettext
  import Ecto.Query, warn: false
  alias Cannery.{Accounts.User, Containers, Containers.Container, Repo}
  alias Cannery.ActivityLog.ShotGroup
  alias Cannery.Ammo.{AmmoGroup, AmmoType}
  alias Ecto.Changeset

  @ammo_group_create_limit 10_000

  @doc """
  Returns the list of ammo_types.

  ## Examples

      iex> list_ammo_types(%User{id: 123})
      [%AmmoType{}, ...]

      iex> list_ammo_types("cool", %User{id: 123})
      [%AmmoType{name: "My cool ammo type"}, ...]

  """
  @spec list_ammo_types(User.t()) :: [AmmoType.t()]
  @spec list_ammo_types(search :: nil | String.t(), User.t()) :: [AmmoType.t()]
  def list_ammo_types(search \\ nil, user)

  def list_ammo_types(search, %{id: user_id}) when search |> is_nil() or search == "",
    do: Repo.all(from at in AmmoType, where: at.user_id == ^user_id, order_by: at.name)

  def list_ammo_types(search, %{id: user_id}) when search |> is_binary() do
    trimmed_search = String.trim(search)

    Repo.all(
      from at in AmmoType,
        where: at.user_id == ^user_id,
        where:
          fragment(
            "search @@ websearch_to_tsquery('english', ?)",
            ^trimmed_search
          ),
        order_by: {
          :desc,
          fragment(
            "ts_rank_cd(search, websearch_to_tsquery('english', ?), 4)",
            ^trimmed_search
          )
        }
    )
  end

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
      35

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
      35

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
  Gets the total number of ammo ever bought for an ammo type

  Raises `Ecto.NoResultsError` if the Ammo type does not exist.

  ## Examples

      iex> get_historical_count_for_ammo_type(123, %User{id: 123})
      %AmmoType{}

      iex> get_historical_count_for_ammo_type(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_historical_count_for_ammo_type(AmmoType.t(), User.t()) :: non_neg_integer()
  def get_historical_count_for_ammo_type(
        %AmmoType{user_id: user_id} = ammo_type,
        %User{id: user_id} = user
      ) do
    get_round_count_for_ammo_type(ammo_type, user) +
      get_used_count_for_ammo_type(ammo_type, user)
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
          {:ok, AmmoType.t()} | {:error, AmmoType.changeset()}
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
          {:ok, AmmoType.t()} | {:error, AmmoType.changeset()}
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
          {:ok, AmmoType.t()} | {:error, AmmoType.changeset()}
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
        true = _include_empty
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
        false = _include_empty
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
  Returns the list of ammo_groups for a user and container.

  ## Examples

      iex> list_ammo_groups_for_container(%AmmoType{id: 123}, %User{id: 123})
      [%AmmoGroup{}, ...]

  """
  @spec list_ammo_groups_for_container(Container.t(), User.t()) :: [AmmoGroup.t()]
  @spec list_ammo_groups_for_container(Container.t(), User.t(), include_empty :: boolean()) ::
          [AmmoGroup.t()]
  def list_ammo_groups_for_container(container, user, include_empty \\ false)

  def list_ammo_groups_for_container(
        %Container{id: container_id, user_id: user_id},
        %User{id: user_id},
        true = _include_empty
      ) do
    Repo.all(
      from ag in AmmoGroup,
        left_join: sg in assoc(ag, :shot_groups),
        where: ag.container_id == ^container_id,
        where: ag.user_id == ^user_id,
        preload: [shot_groups: sg],
        order_by: ag.id
    )
  end

  def list_ammo_groups_for_container(
        %Container{id: container_id, user_id: user_id},
        %User{id: user_id},
        false = _include_empty
      ) do
    Repo.all(
      from ag in AmmoGroup,
        left_join: sg in assoc(ag, :shot_groups),
        where: ag.container_id == ^container_id,
        where: ag.user_id == ^user_id,
        where: not (ag.count == 0),
        preload: [shot_groups: sg],
        order_by: ag.id
    )
  end

  @doc """
  Returns the count of ammo_groups for an ammo type.

  ## Examples

      iex> get_ammo_groups_count_for_type(%AmmoType{id: 123}, %User{id: 123})
      3

      iex> get_ammo_groups_count_for_type(%AmmoType{id: 123}, %User{id: 123}, true)
      5

  """
  @spec get_ammo_groups_count_for_type(AmmoType.t(), User.t()) :: [AmmoGroup.t()]
  @spec get_ammo_groups_count_for_type(AmmoType.t(), User.t(), include_empty :: boolean()) ::
          [AmmoGroup.t()]
  def get_ammo_groups_count_for_type(ammo_type, user, include_empty \\ false)

  def get_ammo_groups_count_for_type(
        %AmmoType{id: ammo_type_id, user_id: user_id},
        %User{id: user_id},
        true = _include_empty
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
        false = _include_empty
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
  Returns the count of used ammo_groups for an ammo type.

  ## Examples

      iex> get_used_ammo_groups_count_for_type(%AmmoType{id: 123}, %User{id: 123})
      3

  """
  @spec get_used_ammo_groups_count_for_type(AmmoType.t(), User.t()) :: [AmmoGroup.t()]
  def get_used_ammo_groups_count_for_type(
        %AmmoType{id: ammo_type_id, user_id: user_id},
        %User{id: user_id}
      ) do
    Repo.one!(
      from ag in AmmoGroup,
        where: ag.user_id == ^user_id,
        where: ag.ammo_type_id == ^ammo_type_id,
        where: ag.count == 0,
        distinct: true,
        select: count(ag.id)
    ) || 0
  end

  @doc """
  Returns the list of ammo_groups.

  ## Examples

      iex> list_ammo_groups(%User{id: 123})
      [%AmmoGroup{}, ...]

      iex> list_ammo_groups("cool", true, %User{id: 123})
      [%AmmoGroup{notes: "My cool ammo group"}, ...]

  """
  @spec list_ammo_groups(User.t()) :: [AmmoGroup.t()]
  @spec list_ammo_groups(search :: nil | String.t(), User.t()) :: [AmmoGroup.t()]
  @spec list_ammo_groups(search :: nil | String.t(), include_empty :: boolean(), User.t()) ::
          [AmmoGroup.t()]
  def list_ammo_groups(search \\ nil, include_empty \\ false, %{id: user_id}) do
    from(
      ag in AmmoGroup,
      as: :ag,
      left_join: sg in assoc(ag, :shot_groups),
      as: :sg,
      join: at in assoc(ag, :ammo_type),
      as: :at,
      join: c in assoc(ag, :container),
      as: :c,
      left_join: t in assoc(c, :tags),
      as: :t,
      where: ag.user_id == ^user_id,
      preload: [shot_groups: sg, ammo_type: at, container: {c, tags: t}],
      order_by: ag.id
    )
    |> list_ammo_groups_include_empty(include_empty)
    |> list_ammo_groups_search(search)
    |> Repo.all()
  end

  defp list_ammo_groups_include_empty(query, true), do: query

  defp list_ammo_groups_include_empty(query, false) do
    query |> where([ag], not (ag.count == 0))
  end

  defp list_ammo_groups_search(query, nil), do: query
  defp list_ammo_groups_search(query, ""), do: query

  defp list_ammo_groups_search(query, search) do
    trimmed_search = String.trim(search)

    query
    |> where(
      [ag: ag, at: at, c: c, t: t],
      fragment(
        "? @@ websearch_to_tsquery('english', ?)",
        ag.search,
        ^trimmed_search
      ) or
        fragment(
          "? @@ websearch_to_tsquery('english', ?)",
          at.search,
          ^trimmed_search
        ) or
        fragment(
          "? @@ websearch_to_tsquery('english', ?)",
          c.search,
          ^trimmed_search
        ) or
        fragment(
          "? @@ websearch_to_tsquery('english', ?)",
          t.search,
          ^trimmed_search
        )
    )
    |> order_by(
      [ag: ag],
      desc:
        fragment(
          "ts_rank_cd(?, websearch_to_tsquery('english', ?), 4)",
          ag.search,
          ^trimmed_search
        )
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
  Returns the last entered shot group for an ammo group
  """
  @spec get_last_used_shot_group(AmmoGroup.t()) :: ShotGroup.t() | nil
  def get_last_used_shot_group(%AmmoGroup{} = ammo_group) do
    ammo_group
    |> Repo.preload(:shot_groups)
    |> Map.fetch!(:shot_groups)
    |> Enum.max_by(fn %{date: date} -> date end, Date, fn -> nil end)
  end

  @doc """
  Calculates the percentage remaining of an ammo group out of 100
  """
  @spec get_percentage_remaining(AmmoGroup.t()) :: non_neg_integer()
  def get_percentage_remaining(%AmmoGroup{count: 0}), do: 0

  def get_percentage_remaining(%AmmoGroup{count: count} = ammo_group) do
    ammo_group = ammo_group |> Repo.preload(:shot_groups)

    shot_group_sum =
      ammo_group.shot_groups
      |> Enum.map(fn %{count: count} -> count end)
      |> Enum.sum()

    round(count / (count + shot_group_sum) * 100)
  end

  @doc """
  Gets the original count for an ammo group
  """
  @spec get_original_count(AmmoGroup.t()) :: non_neg_integer()
  def get_original_count(%AmmoGroup{count: count} = ammo_group) do
    count + get_used_count(ammo_group)
  end

  @doc """
  Calculates the CPR for a single ammo group
  """
  @spec get_cpr(AmmoGroup.t()) :: nil | float()
  def get_cpr(%AmmoGroup{price_paid: nil}), do: nil

  def get_cpr(%AmmoGroup{price_paid: price_paid} = ammo_group),
    do: calculate_cpr(price_paid, get_original_count(ammo_group))

  @spec calculate_cpr(price_paid :: float() | nil, count :: integer()) :: float() | nil
  defp calculate_cpr(nil, _count), do: nil
  defp calculate_cpr(_price_paid, 0), do: nil
  defp calculate_cpr(price_paid, total_count), do: price_paid / total_count

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
          | {:error, AmmoGroup.changeset()}
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
          {:ok, AmmoGroup.t()} | {:error, AmmoGroup.changeset()}
  def update_ammo_group(
        %AmmoGroup{user_id: user_id} = ammo_group,
        attrs,
        %User{id: user_id} = user
      ),
      do: ammo_group |> AmmoGroup.update_changeset(attrs, user) |> Repo.update()

  @doc """
  Deletes a ammo_group.

  ## Examples

      iex> delete_ammo_group(ammo_group, %User{id: 123})
      {:ok, %AmmoGroup{}}

      iex> delete_ammo_group(ammo_group, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec delete_ammo_group(AmmoGroup.t(), User.t()) ::
          {:ok, AmmoGroup.t()} | {:error, AmmoGroup.changeset()}
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
