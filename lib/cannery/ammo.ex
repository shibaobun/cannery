defmodule Cannery.Ammo do
  @moduledoc """
  The Ammo context.
  """

  import CanneryWeb.Gettext
  import Ecto.Query, warn: false
  alias Cannery.{Accounts.User, Containers, Repo}
  alias Cannery.Containers.{Container, ContainerTag, Tag}
  alias Cannery.{ActivityLog, ActivityLog.ShotGroup}
  alias Cannery.Ammo.{AmmoGroup, AmmoType}
  alias Ecto.Changeset

  @ammo_group_create_limit 10_000
  @ammo_group_preloads [:ammo_type]
  @ammo_type_preloads [:ammo_groups]

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

  def list_ammo_types(search, %{id: user_id}) when search |> is_nil() or search == "" do
    Repo.all(
      from at in AmmoType,
        where: at.user_id == ^user_id,
        order_by: at.name,
        preload: ^@ammo_type_preloads
    )
  end

  def list_ammo_types(search, %{id: user_id}) when search |> is_binary() do
    trimmed_search = String.trim(search)

    Repo.all(
      from at in AmmoType,
        where: at.user_id == ^user_id,
        where:
          fragment(
            "? @@ websearch_to_tsquery('english', ?)",
            at.search,
            ^trimmed_search
          ),
        order_by: {
          :desc,
          fragment(
            "ts_rank_cd(?, websearch_to_tsquery('english', ?), 4)",
            at.search,
            ^trimmed_search
          )
        },
        preload: ^@ammo_type_preloads
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
  def get_ammo_type!(id, %User{id: user_id}) do
    Repo.one!(
      from at in AmmoType,
        where: at.id == ^id,
        where: at.user_id == ^user_id,
        preload: ^@ammo_type_preloads
    )
  end

  @doc """
  Gets the average cost of an ammo type from ammo groups with price information.

  ## Examples

      iex> get_average_cost_for_ammo_type(
      ...>   %AmmoType{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      1.50

  """
  @spec get_average_cost_for_ammo_type(AmmoType.t(), User.t()) :: float() | nil
  def get_average_cost_for_ammo_type(%AmmoType{id: ammo_type_id} = ammo_type, user) do
    [ammo_type]
    |> get_average_cost_for_ammo_types(user)
    |> Map.get(ammo_type_id)
  end

  @doc """
  Gets the average cost of ammo types from ammo groups with price information
  for multiple ammo types.

  ## Examples

      iex> get_average_cost_for_ammo_types(
      ...>   [%AmmoType{id: 123, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      1.50

  """
  @spec get_average_cost_for_ammo_types([AmmoType.t()], User.t()) ::
          %{optional(AmmoType.id()) => float()}
  def get_average_cost_for_ammo_types(ammo_types, %User{id: user_id}) do
    ammo_type_ids =
      ammo_types
      |> Enum.map(fn %AmmoType{id: ammo_type_id, user_id: ^user_id} -> ammo_type_id end)

    sg_total_query =
      from sg in ShotGroup,
        where: not (sg.count |> is_nil()),
        group_by: sg.ammo_group_id,
        select: %{ammo_group_id: sg.ammo_group_id, total: sum(sg.count)}

    Repo.all(
      from ag in AmmoGroup,
        as: :ammo_group,
        left_join: sg_query in subquery(sg_total_query),
        on: ag.id == sg_query.ammo_group_id,
        where: ag.ammo_type_id in ^ammo_type_ids,
        group_by: ag.ammo_type_id,
        where: not (ag.price_paid |> is_nil()),
        select:
          {ag.ammo_type_id, sum(ag.price_paid) / sum(ag.count + coalesce(sg_query.total, 0))}
    )
    |> Map.new()
  end

  @doc """
  Gets the total number of rounds for an ammo type

  ## Examples

      iex> get_round_count_for_ammo_type(
      ...>   %AmmoType{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      35

  """
  @spec get_round_count_for_ammo_type(AmmoType.t(), User.t()) :: non_neg_integer()
  def get_round_count_for_ammo_type(%AmmoType{id: ammo_type_id} = ammo_type, user) do
    [ammo_type]
    |> get_round_count_for_ammo_types(user)
    |> Map.get(ammo_type_id, 0)
  end

  @doc """
  Gets the total number of rounds for multiple ammo types

  ## Examples

      iex> get_round_count_for_ammo_types(
      ...>   [%AmmoType{id: 123, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 35}

  """
  @spec get_round_count_for_ammo_types([AmmoType.t()], User.t()) ::
          %{optional(AmmoType.id()) => non_neg_integer()}
  def get_round_count_for_ammo_types(ammo_types, %User{id: user_id}) do
    ammo_type_ids =
      ammo_types
      |> Enum.map(fn %AmmoType{id: ammo_type_id, user_id: ^user_id} -> ammo_type_id end)

    Repo.all(
      from ag in AmmoGroup,
        where: ag.ammo_type_id in ^ammo_type_ids,
        where: ag.user_id == ^user_id,
        group_by: ag.ammo_type_id,
        select: {ag.ammo_type_id, sum(ag.count)}
    )
    |> Map.new()
  end

  @doc """
  Gets the total number of ammo ever bought for an ammo type

  ## Examples

      iex> get_historical_count_for_ammo_type(
      ...>   %AmmoType{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      5

  """
  @spec get_historical_count_for_ammo_type(AmmoType.t(), User.t()) :: non_neg_integer()
  def get_historical_count_for_ammo_type(%AmmoType{id: ammo_type_id} = ammo_type, user) do
    [ammo_type]
    |> get_historical_count_for_ammo_types(user)
    |> Map.get(ammo_type_id, 0)
  end

  @doc """
  Gets the total number of ammo ever bought for multiple ammo types

  ## Examples

      iex> get_historical_count_for_ammo_types(
      ...>   [%AmmoType{id: 123, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 5}

  """
  @spec get_historical_count_for_ammo_types([AmmoType.t()], User.t()) ::
          %{optional(AmmoType.id()) => non_neg_integer()}
  def get_historical_count_for_ammo_types(ammo_types, %User{id: user_id} = user) do
    used_counts = ammo_types |> ActivityLog.get_used_count_for_ammo_types(user)
    round_counts = ammo_types |> get_round_count_for_ammo_types(user)

    ammo_types
    |> Enum.filter(fn %AmmoType{id: ammo_type_id, user_id: ^user_id} ->
      Map.has_key?(used_counts, ammo_type_id) or Map.has_key?(round_counts, ammo_type_id)
    end)
    |> Map.new(fn %{id: ammo_type_id} ->
      historical_count =
        Map.get(used_counts, ammo_type_id, 0) + Map.get(round_counts, ammo_type_id, 0)

      {ammo_type_id, historical_count}
    end)
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
  def create_ammo_type(attrs \\ %{}, %User{} = user) do
    %AmmoType{}
    |> AmmoType.create_changeset(user, attrs)
    |> Repo.insert()
    |> case do
      {:ok, ammo_type} -> {:ok, ammo_type |> preload_ammo_type()}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @spec preload_ammo_type(AmmoType.t()) :: AmmoType.t()
  @spec preload_ammo_type([AmmoType.t()]) :: [AmmoType.t()]
  defp preload_ammo_type(ammo_type_or_ammo_types) do
    ammo_type_or_ammo_types |> Repo.preload(@ammo_type_preloads)
  end

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
  def update_ammo_type(%AmmoType{user_id: user_id} = ammo_type, attrs, %User{id: user_id}) do
    ammo_type
    |> AmmoType.update_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, ammo_type} -> {:ok, ammo_type |> preload_ammo_type()}
      {:error, changeset} -> {:error, changeset}
    end
  end

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
  def delete_ammo_type(%AmmoType{user_id: user_id} = ammo_type, %User{id: user_id}) do
    ammo_type
    |> Repo.delete()
    |> case do
      {:ok, ammo_type} -> {:ok, ammo_type |> preload_ammo_type()}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Deletes a ammo_type.

  ## Examples

      iex> delete_ammo_type!(ammo_type, %User{id: 123})
      %AmmoType{}

  """
  @spec delete_ammo_type!(AmmoType.t(), User.t()) :: AmmoType.t()
  def delete_ammo_type!(ammo_type, user) do
    {:ok, ammo_type} = delete_ammo_type(ammo_type, user)
    ammo_type
  end

  @doc """
  Returns the list of ammo_groups for a user and type.

  ## Examples

      iex> list_ammo_groups_for_type(
      ...>   %AmmoType{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      [%AmmoGroup{}, ...]

      iex> list_ammo_groups_for_type(
      ...>   %AmmoType{id: 123, user_id: 456},
      ...>   %User{id: 456},
      ...>   true
      ...> )
      [%AmmoGroup{}, %AmmoGroup{}, ...]

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
        where: ag.ammo_type_id == ^ammo_type_id,
        where: ag.user_id == ^user_id,
        preload: ^@ammo_group_preloads
    )
  end

  def list_ammo_groups_for_type(
        %AmmoType{id: ammo_type_id, user_id: user_id},
        %User{id: user_id},
        false = _include_empty
      ) do
    Repo.all(
      from ag in AmmoGroup,
        where: ag.ammo_type_id == ^ammo_type_id,
        where: ag.user_id == ^user_id,
        where: not (ag.count == 0),
        preload: ^@ammo_group_preloads
    )
  end

  @doc """
  Returns the list of ammo_groups for a user and container.

  ## Examples

      iex> list_ammo_groups_for_container(
      ...>   %Container{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      [%AmmoGroup{}, ...]

      iex> list_ammo_groups_for_container(
      ...>   %Container{id: 123, user_id: 456},
      ...>   %User{id: 456},
      ...>   true
      ...> )
      [%AmmoGroup{}, %AmmoGroup{}, ...]

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
        where: ag.container_id == ^container_id,
        where: ag.user_id == ^user_id,
        preload: ^@ammo_group_preloads
    )
  end

  def list_ammo_groups_for_container(
        %Container{id: container_id, user_id: user_id},
        %User{id: user_id},
        false = _include_empty
      ) do
    Repo.all(
      from ag in AmmoGroup,
        where: ag.container_id == ^container_id,
        where: ag.user_id == ^user_id,
        where: not (ag.count == 0),
        preload: ^@ammo_group_preloads
    )
  end

  @doc """
  Returns the count of ammo_groups for an ammo type.

  ## Examples

      iex> get_ammo_groups_count_for_type(
      ...>   %AmmoType{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      3

      iex> get_ammo_groups_count_for_type(
      ...>   %AmmoType{id: 123, user_id: 456},
      ...>   %User{id: 456},
      ...>   true
      ...> )
      5

  """
  @spec get_ammo_groups_count_for_type(AmmoType.t(), User.t()) :: non_neg_integer()
  @spec get_ammo_groups_count_for_type(AmmoType.t(), User.t(), include_empty :: boolean()) ::
          non_neg_integer()
  def get_ammo_groups_count_for_type(
        %AmmoType{id: ammo_type_id} = ammo_type,
        user,
        include_empty \\ false
      ) do
    [ammo_type]
    |> get_ammo_groups_count_for_types(user, include_empty)
    |> Map.get(ammo_type_id, 0)
  end

  @doc """
  Returns the count of ammo_groups for multiple ammo types.

  ## Examples

      iex> get_ammo_groups_count_for_types(
      ...>   [%AmmoType{id: 123, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      3

      iex> get_ammo_groups_count_for_types(
      ...>   [%AmmoType{id: 123, user_id: 456}],
      ...>   %User{id: 456},
      ...>   true
      ...> )
      5

  """
  @spec get_ammo_groups_count_for_types([AmmoType.t()], User.t()) ::
          %{optional(AmmoType.id()) => non_neg_integer()}
  @spec get_ammo_groups_count_for_types([AmmoType.t()], User.t(), include_empty :: boolean()) ::
          %{optional(AmmoType.id()) => non_neg_integer()}
  def get_ammo_groups_count_for_types(ammo_types, %User{id: user_id}, include_empty \\ false) do
    ammo_type_ids =
      ammo_types
      |> Enum.map(fn %AmmoType{id: ammo_type_id, user_id: ^user_id} -> ammo_type_id end)

    from(ag in AmmoGroup,
      where: ag.user_id == ^user_id,
      where: ag.ammo_type_id in ^ammo_type_ids,
      group_by: ag.ammo_type_id,
      select: {ag.ammo_type_id, count(ag.id)}
    )
    |> maybe_include_empty(include_empty)
    |> Repo.all()
    |> Map.new()
  end

  defp maybe_include_empty(query, true), do: query

  defp maybe_include_empty(query, _false) do
    query |> where([ag], not (ag.count == 0))
  end

  @doc """
  Returns the count of used ammo_groups for an ammo type.

  ## Examples

      iex> get_used_ammo_groups_count_for_type(
      ...>   %AmmoType{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      3

  """
  @spec get_used_ammo_groups_count_for_type(AmmoType.t(), User.t()) :: non_neg_integer()
  def get_used_ammo_groups_count_for_type(%AmmoType{id: ammo_type_id} = ammo_type, user) do
    [ammo_type]
    |> get_used_ammo_groups_count_for_types(user)
    |> Map.get(ammo_type_id, 0)
  end

  @doc """
  Returns the count of used ammo_groups for multiple ammo types.

  ## Examples

      iex> get_used_ammo_groups_count_for_types(
      ...>   [%AmmoType{id: 123, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 3}

  """
  @spec get_used_ammo_groups_count_for_types([AmmoType.t()], User.t()) ::
          %{optional(AmmoType.id()) => non_neg_integer()}
  def get_used_ammo_groups_count_for_types(ammo_types, %User{id: user_id}) do
    ammo_type_ids =
      ammo_types
      |> Enum.map(fn %AmmoType{id: ammo_type_id, user_id: ^user_id} -> ammo_type_id end)

    Repo.all(
      from ag in AmmoGroup,
        where: ag.user_id == ^user_id,
        where: ag.ammo_type_id in ^ammo_type_ids,
        where: ag.count == 0,
        group_by: ag.ammo_type_id,
        select: {ag.ammo_type_id, count(ag.id)}
    )
    |> Map.new()
  end

  @doc """
  Returns number of ammo packs in a container.

  ## Examples

      iex> get_ammo_groups_count_for_container(
      ...>   %Container{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      3

  """
  @spec get_ammo_groups_count_for_container!(Container.t(), User.t()) :: non_neg_integer()
  def get_ammo_groups_count_for_container!(
        %Container{id: container_id} = container,
        %User{} = user
      ) do
    [container]
    |> get_ammo_groups_count_for_containers(user)
    |> Map.get(container_id, 0)
  end

  @doc """
  Returns number of ammo packs in multiple containers.

  ## Examples

      iex> get_ammo_groups_count_for_containers(
      ...>   [%Container{id: 123, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 3}

  """
  @spec get_ammo_groups_count_for_containers([Container.t()], User.t()) :: %{
          Container.id() => non_neg_integer()
        }
  def get_ammo_groups_count_for_containers(containers, %User{id: user_id}) do
    container_ids =
      containers
      |> Enum.map(fn %Container{id: container_id, user_id: ^user_id} -> container_id end)

    Repo.all(
      from ag in AmmoGroup,
        where: ag.container_id in ^container_ids,
        where: ag.count != 0,
        group_by: ag.container_id,
        select: {ag.container_id, count(ag.id)}
    )
    |> Map.new()
  end

  @doc """
  Returns number of rounds in a container.

  ## Examples

      iex> get_round_count_for_container(
      ...>   %Container{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      5

  """
  @spec get_round_count_for_container!(Container.t(), User.t()) :: non_neg_integer()
  def get_round_count_for_container!(%Container{id: container_id} = container, user) do
    [container]
    |> get_round_count_for_containers(user)
    |> Map.get(container_id, 0)
  end

  @doc """
  Returns number of ammo packs in multiple containers.

  ## Examples

      iex> get_round_count_for_containers(
      ...>   [%Container{id: 123, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 5}

  """
  @spec get_round_count_for_containers([Container.t()], User.t()) ::
          %{Container.id() => non_neg_integer()}
  def get_round_count_for_containers(containers, %User{id: user_id}) do
    container_ids =
      containers
      |> Enum.map(fn %Container{id: container_id, user_id: ^user_id} -> container_id end)

    Repo.all(
      from ag in AmmoGroup,
        where: ag.container_id in ^container_ids,
        group_by: ag.container_id,
        select: {ag.container_id, sum(ag.count)}
    )
    |> Map.new()
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
      join: at in assoc(ag, :ammo_type),
      as: :at,
      join: c in Container,
      on: ag.container_id == c.id,
      on: ag.user_id == c.user_id,
      as: :c,
      left_join: ct in ContainerTag,
      on: c.id == ct.container_id,
      left_join: t in Tag,
      on: ct.tag_id == t.id,
      on: c.user_id == t.user_id,
      as: :t,
      where: ag.user_id == ^user_id,
      preload: ^@ammo_group_preloads
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
        where: ag.user_id == ^user_id,
        where: ag.staged == true,
        preload: ^@ammo_group_preloads
    )
  end

  @doc """
  Gets a single ammo_group.

  Raises `KeyError` if the Ammo group does not exist.

  ## Examples

      iex> get_ammo_group!(123, %User{id: 123})
      %AmmoGroup{}

      iex> get_ammo_group!(456, %User{id: 123})
      ** (KeyError)

  """
  @spec get_ammo_group!(AmmoGroup.id(), User.t()) :: AmmoGroup.t()
  def get_ammo_group!(id, user) do
    [id] |> get_ammo_groups(user) |> Map.fetch!(id)
  end

  @doc """
  Gets a group of ammo_groups by their ID.

  ## Examples

      iex> get_ammo_groups([123, 456], %User{id: 123})
      %{123 => %AmmoGroup{}, 456 => %AmmoGroup{}}

  """
  @spec get_ammo_groups([AmmoGroup.id()], User.t()) ::
          %{optional(AmmoGroup.id()) => AmmoGroup.t()}
  def get_ammo_groups(ids, %User{id: user_id}) do
    Repo.all(
      from ag in AmmoGroup,
        where: ag.id in ^ids,
        where: ag.user_id == ^user_id,
        preload: ^@ammo_group_preloads,
        select: {ag.id, ag}
    )
    |> Map.new()
  end

  @doc """
  Calculates the percentage remaining of an ammo group out of 100

  ## Examples

      iex> get_percentage_remaining(
      ...>   %AmmoGroup{id: 123, count: 5, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      100

  """
  @spec get_percentage_remaining(AmmoGroup.t(), User.t()) :: non_neg_integer()
  def get_percentage_remaining(%AmmoGroup{count: 0, user_id: user_id}, %User{id: user_id}) do
    0
  end

  def get_percentage_remaining(%AmmoGroup{count: count} = ammo_group, current_user) do
    round(count / get_original_count(ammo_group, current_user) * 100)
  end

  @doc """
  Gets the original count for an ammo group

  ## Examples

      iex> get_original_count(
      ...>   %AmmoGroup{id: 123, count: 5, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      5

  """
  @spec get_original_count(AmmoGroup.t(), User.t()) :: non_neg_integer()
  def get_original_count(%AmmoGroup{id: ammo_group_id} = ammo_group, current_user) do
    [ammo_group]
    |> get_original_counts(current_user)
    |> Map.fetch!(ammo_group_id)
  end

  @doc """
  Gets the original counts for multiple ammo groups

  ## Examples

      iex> get_original_counts(
      ...>   [%AmmoGroup{id: 123, count: 5, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 5}

  """
  @spec get_original_counts([AmmoGroup.t()], User.t()) ::
          %{optional(AmmoGroup.id()) => non_neg_integer()}
  def get_original_counts(ammo_groups, %User{id: user_id} = current_user) do
    used_counts = ActivityLog.get_used_counts(ammo_groups, current_user)

    ammo_groups
    |> Map.new(fn %AmmoGroup{id: ammo_group_id, count: count, user_id: ^user_id} ->
      {ammo_group_id, count + Map.get(used_counts, ammo_group_id, 0)}
    end)
  end

  @doc """
  Calculates the CPR for a single ammo group

  ## Examples

      iex> get_cpr(
      ...>   %AmmoGroup{id: 123, price_paid: 5, count: 5, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      1

  """
  @spec get_cpr(AmmoGroup.t(), User.t()) :: float() | nil
  def get_cpr(%AmmoGroup{id: ammo_group_id} = ammo_group, user) do
    [ammo_group]
    |> get_cprs(user)
    |> Map.get(ammo_group_id)
  end

  @doc """
  Calculates the CPR for multiple ammo groups

  ## Examples

      iex> get_cprs(
      ...>   [%AmmoGroup{id: 123, price_paid: 5, count: 5, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 1}

  """
  @spec get_cprs([AmmoGroup.t()], User.t()) :: %{optional(AmmoGroup.id()) => float()}
  def get_cprs(ammo_groups, %User{id: user_id} = current_user) do
    original_counts = get_original_counts(ammo_groups, current_user)

    ammo_groups
    |> Enum.reject(fn %AmmoGroup{price_paid: price_paid, user_id: ^user_id} ->
      price_paid |> is_nil()
    end)
    |> Map.new(fn %{id: ammo_group_id, price_paid: price_paid} ->
      {ammo_group_id, calculate_cpr(price_paid, Map.fetch!(original_counts, ammo_group_id))}
    end)
  end

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

      {:ok, {count, inserted_ammo_groups |> preload_ammo_group()}}
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
      when is_binary(ammo_type_id) and is_binary(container_id) do
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

  @spec preload_ammo_group(AmmoGroup.t()) :: AmmoGroup.t()
  @spec preload_ammo_group([AmmoGroup.t()]) :: [AmmoGroup.t()]
  defp preload_ammo_group(ammo_group_or_ammo_groups) do
    ammo_group_or_ammo_groups |> Repo.preload(@ammo_group_preloads)
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
      ) do
    ammo_group
    |> AmmoGroup.update_changeset(attrs, user)
    |> Repo.update()
    |> case do
      {:ok, ammo_group} -> {:ok, ammo_group |> preload_ammo_group()}
      {:error, changeset} -> {:error, changeset}
    end
  end

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
  def delete_ammo_group(%AmmoGroup{user_id: user_id} = ammo_group, %User{id: user_id}) do
    ammo_group
    |> Repo.delete()
    |> case do
      {:ok, ammo_group} -> {:ok, ammo_group |> preload_ammo_group()}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Deletes a ammo_group.

  ## Examples

      iex> delete_ammo_group!(ammo_group, %User{id: 123})
      %AmmoGroup{}

  """
  @spec delete_ammo_group!(AmmoGroup.t(), User.t()) :: AmmoGroup.t()
  def delete_ammo_group!(ammo_group, user) do
    {:ok, ammo_group} = delete_ammo_group(ammo_group, user)
    ammo_group
  end
end
