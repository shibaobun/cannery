defmodule Cannery.Ammo do
  @moduledoc """
  The Ammo context.
  """

  import CanneryWeb.Gettext
  import Ecto.Query, warn: false
  alias Cannery.{Accounts.User, Containers, Repo}
  alias Cannery.Containers.{Container, ContainerTag, Tag}
  alias Cannery.{ActivityLog, ActivityLog.ShotRecord}
  alias Cannery.Ammo.{Pack, Type}
  alias Ecto.{Changeset, Queryable}

  @pack_create_limit 10_000
  @pack_preloads [:type]
  @type_preloads [:packs]

  @doc """
  Returns the list of types.

  ## Examples

      iex> list_types(%User{id: 123}, :all)
      [%Type{}, ...]

      iex> list_types("cool", %User{id: 123}, :shotgun)
      [%Type{name: "My cool type", class: :shotgun}, ...]

  """
  @spec list_types(User.t(), Type.class() | :all) :: [Type.t()]
  @spec list_types(search :: nil | String.t(), User.t(), Type.class() | :all) ::
          [Type.t()]
  def list_types(search \\ nil, user, type)

  def list_types(search, %{id: user_id}, type) do
    from(at in Type,
      as: :at,
      where: at.user_id == ^user_id,
      preload: ^@type_preloads
    )
    |> list_types_filter_type(type)
    |> list_types_filter_search(search)
    |> Repo.all()
  end

  @spec list_types_filter_search(Queryable.t(), search :: String.t() | nil) :: Queryable.t()
  defp list_types_filter_search(query, search) when search in ["", nil],
    do: query |> order_by([at: at], at.name)

  defp list_types_filter_search(query, search) when search |> is_binary() do
    trimmed_search = String.trim(search)

    query
    |> where(
      [at: at],
      fragment(
        "? @@ websearch_to_tsquery('english', ?)",
        at.search,
        ^trimmed_search
      )
    )
    |> order_by(
      [at: at],
      {
        :desc,
        fragment(
          "ts_rank_cd(?, websearch_to_tsquery('english', ?), 4)",
          at.search,
          ^trimmed_search
        )
      }
    )
  end

  @spec list_types_filter_type(Queryable.t(), Type.class() | :all) :: Queryable.t()
  defp list_types_filter_type(query, :rifle),
    do: query |> where([at: at], at.class == :rifle)

  defp list_types_filter_type(query, :pistol),
    do: query |> where([at: at], at.class == :pistol)

  defp list_types_filter_type(query, :shotgun),
    do: query |> where([at: at], at.class == :shotgun)

  defp list_types_filter_type(query, _all), do: query

  @doc """
  Returns a count of types.

  ## Examples

      iex> get_types_count!(%User{id: 123})
      3

  """
  @spec get_types_count!(User.t()) :: integer()
  def get_types_count!(%User{id: user_id}) do
    Repo.one(
      from at in Type,
        where: at.user_id == ^user_id,
        select: count(at.id),
        distinct: true
    ) || 0
  end

  @doc """
  Gets a single type.

  Raises `Ecto.NoResultsError` if the type does not exist.

  ## Examples

      iex> get_type!(123, %User{id: 123})
      %Type{}

      iex> get_type!(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_type!(Type.id(), User.t()) :: Type.t()
  def get_type!(id, %User{id: user_id}) do
    Repo.one!(
      from at in Type,
        where: at.id == ^id,
        where: at.user_id == ^user_id,
        preload: ^@type_preloads
    )
  end

  @doc """
  Gets the average cost of a type from packs with price information.

  ## Examples

      iex> get_average_cost_for_type(
      ...>   %Type{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      1.50

  """
  @spec get_average_cost_for_type(Type.t(), User.t()) :: float() | nil
  def get_average_cost_for_type(%Type{id: type_id} = type, user) do
    [type]
    |> get_average_cost_for_types(user)
    |> Map.get(type_id)
  end

  @doc """
  Gets the average cost of types from packs with price information
  for multiple types.

  ## Examples

      iex> get_average_cost_for_types(
      ...>   [%Type{id: 123, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      1.50

  """
  @spec get_average_cost_for_types([Type.t()], User.t()) ::
          %{optional(Type.id()) => float()}
  def get_average_cost_for_types(types, %User{id: user_id}) do
    type_ids =
      types
      |> Enum.map(fn %Type{id: type_id, user_id: ^user_id} -> type_id end)

    sg_total_query =
      from sg in ShotRecord,
        where: not (sg.count |> is_nil()),
        group_by: sg.pack_id,
        select: %{pack_id: sg.pack_id, total: sum(sg.count)}

    Repo.all(
      from ag in Pack,
        as: :pack,
        left_join: sg_query in subquery(sg_total_query),
        on: ag.id == sg_query.pack_id,
        where: ag.type_id in ^type_ids,
        group_by: ag.type_id,
        where: not (ag.price_paid |> is_nil()),
        select: {ag.type_id, sum(ag.price_paid) / sum(ag.count + coalesce(sg_query.total, 0))}
    )
    |> Map.new()
  end

  @doc """
  Gets the total number of rounds for a type

  ## Examples

      iex> get_round_count_for_type(
      ...>   %Type{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      35

  """
  @spec get_round_count_for_type(Type.t(), User.t()) :: non_neg_integer()
  def get_round_count_for_type(%Type{id: type_id} = type, user) do
    [type]
    |> get_round_count_for_types(user)
    |> Map.get(type_id, 0)
  end

  @doc """
  Gets the total number of rounds for multiple types

  ## Examples

      iex> get_round_count_for_types(
      ...>   [%Type{id: 123, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 35}

  """
  @spec get_round_count_for_types([Type.t()], User.t()) ::
          %{optional(Type.id()) => non_neg_integer()}
  def get_round_count_for_types(types, %User{id: user_id}) do
    type_ids =
      types
      |> Enum.map(fn %Type{id: type_id, user_id: ^user_id} -> type_id end)

    Repo.all(
      from ag in Pack,
        where: ag.type_id in ^type_ids,
        where: ag.user_id == ^user_id,
        group_by: ag.type_id,
        select: {ag.type_id, sum(ag.count)}
    )
    |> Map.new()
  end

  @doc """
  Gets the total number of ammo ever bought for a type

  ## Examples

      iex> get_historical_count_for_type(
      ...>   %Type{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      5

  """
  @spec get_historical_count_for_type(Type.t(), User.t()) :: non_neg_integer()
  def get_historical_count_for_type(%Type{id: type_id} = type, user) do
    [type]
    |> get_historical_count_for_types(user)
    |> Map.get(type_id, 0)
  end

  @doc """
  Gets the total number of ammo ever bought for multiple types

  ## Examples

      iex> get_historical_count_for_types(
      ...>   [%Type{id: 123, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 5}

  """
  @spec get_historical_count_for_types([Type.t()], User.t()) ::
          %{optional(Type.id()) => non_neg_integer()}
  def get_historical_count_for_types(types, %User{id: user_id} = user) do
    used_counts = types |> ActivityLog.get_used_count_for_types(user)
    round_counts = types |> get_round_count_for_types(user)

    types
    |> Enum.filter(fn %Type{id: type_id, user_id: ^user_id} ->
      Map.has_key?(used_counts, type_id) or Map.has_key?(round_counts, type_id)
    end)
    |> Map.new(fn %{id: type_id} ->
      historical_count = Map.get(used_counts, type_id, 0) + Map.get(round_counts, type_id, 0)

      {type_id, historical_count}
    end)
  end

  @doc """
  Creates a type.

  ## Examples

      iex> create_type(%{field: value}, %User{id: 123})
      {:ok, %Type{}}

      iex> create_type(%{field: bad_value}, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec create_type(attrs :: map(), User.t()) ::
          {:ok, Type.t()} | {:error, Type.changeset()}
  def create_type(attrs \\ %{}, %User{} = user) do
    %Type{}
    |> Type.create_changeset(user, attrs)
    |> Repo.insert()
    |> case do
      {:ok, type} -> {:ok, type |> preload_type()}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @spec preload_type(Type.t()) :: Type.t()
  @spec preload_type([Type.t()]) :: [Type.t()]
  defp preload_type(type_or_types) do
    type_or_types |> Repo.preload(@type_preloads)
  end

  @doc """
  Updates a type.

  ## Examples

      iex> update_type(type, %{field: new_value}, %User{id: 123})
      {:ok, %Type{}}

      iex> update_type(type, %{field: bad_value}, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec update_type(Type.t(), attrs :: map(), User.t()) ::
          {:ok, Type.t()} | {:error, Type.changeset()}
  def update_type(%Type{user_id: user_id} = type, attrs, %User{id: user_id}) do
    type
    |> Type.update_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, type} -> {:ok, type |> preload_type()}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Deletes a type.

  ## Examples

      iex> delete_type(type, %User{id: 123})
      {:ok, %Type{}}

      iex> delete_type(type, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec delete_type(Type.t(), User.t()) ::
          {:ok, Type.t()} | {:error, Type.changeset()}
  def delete_type(%Type{user_id: user_id} = type, %User{id: user_id}) do
    type
    |> Repo.delete()
    |> case do
      {:ok, type} -> {:ok, type |> preload_type()}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Deletes a type.

  ## Examples

      iex> delete_type!(type, %User{id: 123})
      %Type{}

  """
  @spec delete_type!(Type.t(), User.t()) :: Type.t()
  def delete_type!(type, user) do
    {:ok, type} = delete_type(type, user)
    type
  end

  @doc """
  Returns the list of packs for a user and type.

  ## Examples

      iex> list_packs_for_type(
      ...>   %Type{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      [%Pack{}, ...]

      iex> list_packs_for_type(
      ...>   %Type{id: 123, user_id: 456},
      ...>   %User{id: 456},
      ...>   true
      ...> )
      [%Pack{}, %Pack{}, ...]

  """
  @spec list_packs_for_type(Type.t(), User.t()) :: [Pack.t()]
  @spec list_packs_for_type(Type.t(), User.t(), show_used :: boolean()) ::
          [Pack.t()]
  def list_packs_for_type(type, user, show_used \\ false)

  def list_packs_for_type(
        %Type{id: type_id, user_id: user_id},
        %User{id: user_id},
        show_used
      ) do
    from(ag in Pack,
      as: :ag,
      where: ag.type_id == ^type_id,
      where: ag.user_id == ^user_id,
      preload: ^@pack_preloads
    )
    |> list_packs_for_type_show_used(show_used)
    |> Repo.all()
  end

  @spec list_packs_for_type_show_used(Queryable.t(), show_used :: boolean()) ::
          Queryable.t()
  def list_packs_for_type_show_used(query, false),
    do: query |> where([ag: ag], ag.count > 0)

  def list_packs_for_type_show_used(query, _true), do: query

  @doc """
  Returns the list of packs for a user and container.

  ## Examples

      iex> list_packs_for_container(
      ...>   %Container{id: 123, user_id: 456},
      ...>   :rifle,
      ...>   %User{id: 456}
      ...> )
      [%Pack{}, ...]

      iex> list_packs_for_container(
      ...>   %Container{id: 123, user_id: 456},
      ...>   :all,
      ...>   %User{id: 456}
      ...> )
      [%Pack{}, %Pack{}, ...]

  """
  @spec list_packs_for_container(
          Container.t(),
          Type.t() | :all,
          User.t()
        ) :: [Pack.t()]
  def list_packs_for_container(
        %Container{id: container_id, user_id: user_id},
        type,
        %User{id: user_id}
      ) do
    from(ag in Pack,
      as: :ag,
      join: at in assoc(ag, :type),
      as: :at,
      where: ag.container_id == ^container_id,
      where: ag.user_id == ^user_id,
      where: ag.count > 0,
      preload: ^@pack_preloads
    )
    |> list_packs_for_container_filter_type(type)
    |> Repo.all()
  end

  @spec list_packs_for_container_filter_type(Queryable.t(), Type.class() | :all) ::
          Queryable.t()
  defp list_packs_for_container_filter_type(query, :rifle),
    do: query |> where([at: at], at.class == :rifle)

  defp list_packs_for_container_filter_type(query, :pistol),
    do: query |> where([at: at], at.class == :pistol)

  defp list_packs_for_container_filter_type(query, :shotgun),
    do: query |> where([at: at], at.class == :shotgun)

  defp list_packs_for_container_filter_type(query, _all), do: query

  @doc """
  Returns a count of packs.

  ## Examples

      iex> get_packs_count!(%User{id: 123})
      3

      iex> get_packs_count!(%User{id: 123}, true)
      4

  """
  @spec get_packs_count!(User.t()) :: integer()
  @spec get_packs_count!(User.t(), show_used :: boolean()) :: integer()
  def get_packs_count!(%User{id: user_id}, show_used \\ false) do
    from(ag in Pack,
      as: :ag,
      where: ag.user_id == ^user_id,
      select: count(ag.id),
      distinct: true
    )
    |> get_packs_count_show_used(show_used)
    |> Repo.one() || 0
  end

  @spec get_packs_count_show_used(Queryable.t(), show_used :: boolean()) :: Queryable.t()
  defp get_packs_count_show_used(query, false),
    do: query |> where([ag: ag], ag.count > 0)

  defp get_packs_count_show_used(query, _true), do: query

  @doc """
  Returns the count of packs for a type.

  ## Examples

      iex> get_packs_count_for_type(
      ...>   %Type{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      3

      iex> get_packs_count_for_type(
      ...>   %Type{id: 123, user_id: 456},
      ...>   %User{id: 456},
      ...>   true
      ...> )
      5

  """
  @spec get_packs_count_for_type(Type.t(), User.t()) :: non_neg_integer()
  @spec get_packs_count_for_type(Type.t(), User.t(), show_used :: boolean()) ::
          non_neg_integer()
  def get_packs_count_for_type(
        %Type{id: type_id} = type,
        user,
        show_used \\ false
      ) do
    [type]
    |> get_packs_count_for_types(user, show_used)
    |> Map.get(type_id, 0)
  end

  @doc """
  Returns the count of packs for multiple types.

  ## Examples

      iex> get_packs_count_for_types(
      ...>   [%Type{id: 123, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      3

      iex> get_packs_count_for_types(
      ...>   [%Type{id: 123, user_id: 456}],
      ...>   %User{id: 456},
      ...>   true
      ...> )
      5

  """
  @spec get_packs_count_for_types([Type.t()], User.t()) ::
          %{optional(Type.id()) => non_neg_integer()}
  @spec get_packs_count_for_types([Type.t()], User.t(), show_used :: boolean()) ::
          %{optional(Type.id()) => non_neg_integer()}
  def get_packs_count_for_types(types, %User{id: user_id}, show_used \\ false) do
    type_ids =
      types
      |> Enum.map(fn %Type{id: type_id, user_id: ^user_id} -> type_id end)

    from(ag in Pack,
      as: :ag,
      where: ag.user_id == ^user_id,
      where: ag.type_id in ^type_ids,
      group_by: ag.type_id,
      select: {ag.type_id, count(ag.id)}
    )
    |> get_packs_count_for_types_maybe_show_used(show_used)
    |> Repo.all()
    |> Map.new()
  end

  @spec get_packs_count_for_types_maybe_show_used(Queryable.t(), show_used :: boolean()) ::
          Queryable.t()
  defp get_packs_count_for_types_maybe_show_used(query, true), do: query

  defp get_packs_count_for_types_maybe_show_used(query, _false) do
    query |> where([ag: ag], not (ag.count == 0))
  end

  @doc """
  Returns the count of used packs for a type.

  ## Examples

      iex> get_used_packs_count_for_type(
      ...>   %Type{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      3

  """
  @spec get_used_packs_count_for_type(Type.t(), User.t()) :: non_neg_integer()
  def get_used_packs_count_for_type(%Type{id: type_id} = type, user) do
    [type]
    |> get_used_packs_count_for_types(user)
    |> Map.get(type_id, 0)
  end

  @doc """
  Returns the count of used packs for multiple types.

  ## Examples

      iex> get_used_packs_count_for_types(
      ...>   [%Type{id: 123, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 3}

  """
  @spec get_used_packs_count_for_types([Type.t()], User.t()) ::
          %{optional(Type.id()) => non_neg_integer()}
  def get_used_packs_count_for_types(types, %User{id: user_id}) do
    type_ids =
      types
      |> Enum.map(fn %Type{id: type_id, user_id: ^user_id} -> type_id end)

    Repo.all(
      from ag in Pack,
        where: ag.user_id == ^user_id,
        where: ag.type_id in ^type_ids,
        where: ag.count == 0,
        group_by: ag.type_id,
        select: {ag.type_id, count(ag.id)}
    )
    |> Map.new()
  end

  @doc """
  Returns number of ammo packs in a container.

  ## Examples

      iex> get_packs_count_for_container(
      ...>   %Container{id: 123, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      3

  """
  @spec get_packs_count_for_container!(Container.t(), User.t()) :: non_neg_integer()
  def get_packs_count_for_container!(
        %Container{id: container_id} = container,
        %User{} = user
      ) do
    [container]
    |> get_packs_count_for_containers(user)
    |> Map.get(container_id, 0)
  end

  @doc """
  Returns number of ammo packs in multiple containers.

  ## Examples

      iex> get_packs_count_for_containers(
      ...>   [%Container{id: 123, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 3}

  """
  @spec get_packs_count_for_containers([Container.t()], User.t()) :: %{
          Container.id() => non_neg_integer()
        }
  def get_packs_count_for_containers(containers, %User{id: user_id}) do
    container_ids =
      containers
      |> Enum.map(fn %Container{id: container_id, user_id: ^user_id} -> container_id end)

    Repo.all(
      from ag in Pack,
        where: ag.container_id in ^container_ids,
        where: ag.count > 0,
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
      from ag in Pack,
        where: ag.container_id in ^container_ids,
        group_by: ag.container_id,
        select: {ag.container_id, sum(ag.count)}
    )
    |> Map.new()
  end

  @doc """
  Returns the list of packs.

  ## Examples

      iex> list_packs(%User{id: 123})
      [%Pack{}, ...]

      iex> list_packs("cool", %User{id: 123}, true)
      [%Pack{notes: "My cool pack"}, ...]

  """
  @spec list_packs(search :: String.t() | nil, Type.class() | :all, User.t()) ::
          [Pack.t()]
  @spec list_packs(
          search :: nil | String.t(),
          Type.class() | :all,
          User.t(),
          show_used :: boolean()
        ) :: [Pack.t()]
  def list_packs(search, type, %{id: user_id}, show_used \\ false) do
    from(ag in Pack,
      as: :ag,
      join: at in assoc(ag, :type),
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
      distinct: ag.id,
      preload: ^@pack_preloads
    )
    |> list_packs_filter_on_type(type)
    |> list_packs_show_used(show_used)
    |> list_packs_search(search)
    |> Repo.all()
  end

  @spec list_packs_filter_on_type(Queryable.t(), Type.class() | :all) :: Queryable.t()
  defp list_packs_filter_on_type(query, :rifle),
    do: query |> where([at: at], at.class == :rifle)

  defp list_packs_filter_on_type(query, :pistol),
    do: query |> where([at: at], at.class == :pistol)

  defp list_packs_filter_on_type(query, :shotgun),
    do: query |> where([at: at], at.class == :shotgun)

  defp list_packs_filter_on_type(query, _all), do: query

  @spec list_packs_show_used(Queryable.t(), show_used :: boolean()) :: Queryable.t()
  defp list_packs_show_used(query, true), do: query

  defp list_packs_show_used(query, _false) do
    query |> where([ag: ag], not (ag.count == 0))
  end

  @spec list_packs_show_used(Queryable.t(), search :: String.t() | nil) :: Queryable.t()
  defp list_packs_search(query, nil), do: query
  defp list_packs_search(query, ""), do: query

  defp list_packs_search(query, search) do
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
  Returns the list of staged packs for a user.

  ## Examples

      iex> list_staged_packs(%User{id: 123})
      [%Pack{}, ...]

  """
  @spec list_staged_packs(User.t()) :: [Pack.t()]
  def list_staged_packs(%User{id: user_id}) do
    Repo.all(
      from ag in Pack,
        where: ag.user_id == ^user_id,
        where: ag.staged == true,
        preload: ^@pack_preloads
    )
  end

  @doc """
  Gets a single pack.

  Raises `KeyError` if the pack does not exist.

  ## Examples

      iex> get_pack!(123, %User{id: 123})
      %Pack{}

      iex> get_pack!(456, %User{id: 123})
      ** (KeyError)

  """
  @spec get_pack!(Pack.id(), User.t()) :: Pack.t()
  def get_pack!(id, user) do
    [id] |> get_packs(user) |> Map.fetch!(id)
  end

  @doc """
  Gets a group of packs by their ID.

  ## Examples

      iex> get_packs([123, 456], %User{id: 123})
      %{123 => %Pack{}, 456 => %Pack{}}

  """
  @spec get_packs([Pack.id()], User.t()) ::
          %{optional(Pack.id()) => Pack.t()}
  def get_packs(ids, %User{id: user_id}) do
    Repo.all(
      from ag in Pack,
        where: ag.id in ^ids,
        where: ag.user_id == ^user_id,
        preload: ^@pack_preloads,
        select: {ag.id, ag}
    )
    |> Map.new()
  end

  @doc """
  Calculates the percentage remaining of a pack out of 100

  ## Examples

      iex> get_percentage_remaining(
      ...>   %Pack{id: 123, count: 5, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      100

  """
  @spec get_percentage_remaining(Pack.t(), User.t()) :: non_neg_integer()
  def get_percentage_remaining(%Pack{id: pack_id} = pack, user) do
    [pack]
    |> get_percentages_remaining(user)
    |> Map.fetch!(pack_id)
  end

  @doc """
  Calculates the percentages remaining of multiple packs out of 100

  ## Examples

      iex> get_percentages_remaining(
      ...>   [%Pack{id: 123, count: 5, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 100}

  """
  @spec get_percentages_remaining([Pack.t()], User.t()) ::
          %{optional(Pack.id()) => non_neg_integer()}
  def get_percentages_remaining(packs, %User{id: user_id} = user) do
    original_counts = get_original_counts(packs, user)

    packs
    |> Map.new(fn %Pack{id: pack_id, count: count, user_id: ^user_id} ->
      percentage =
        case count do
          0 -> 0
          count -> round(count / Map.fetch!(original_counts, pack_id) * 100)
        end

      {pack_id, percentage}
    end)
  end

  @doc """
  Gets the original count for a pack

  ## Examples

      iex> get_original_count(
      ...>   %Pack{id: 123, count: 5, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      5

  """
  @spec get_original_count(Pack.t(), User.t()) :: non_neg_integer()
  def get_original_count(%Pack{id: pack_id} = pack, current_user) do
    [pack]
    |> get_original_counts(current_user)
    |> Map.fetch!(pack_id)
  end

  @doc """
  Gets the original counts for multiple packs

  ## Examples

      iex> get_original_counts(
      ...>   [%Pack{id: 123, count: 5, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 5}

  """
  @spec get_original_counts([Pack.t()], User.t()) ::
          %{optional(Pack.id()) => non_neg_integer()}
  def get_original_counts(packs, %User{id: user_id} = current_user) do
    used_counts = ActivityLog.get_used_counts(packs, current_user)

    packs
    |> Map.new(fn %Pack{id: pack_id, count: count, user_id: ^user_id} ->
      {pack_id, count + Map.get(used_counts, pack_id, 0)}
    end)
  end

  @doc """
  Calculates the CPR for a single pack

  ## Examples

      iex> get_cpr(
      ...>   %Pack{id: 123, price_paid: 5, count: 5, user_id: 456},
      ...>   %User{id: 456}
      ...> )
      1

  """
  @spec get_cpr(Pack.t(), User.t()) :: float() | nil
  def get_cpr(%Pack{id: pack_id} = pack, user) do
    [pack]
    |> get_cprs(user)
    |> Map.get(pack_id)
  end

  @doc """
  Calculates the CPR for multiple packs

  ## Examples

      iex> get_cprs(
      ...>   [%Pack{id: 123, price_paid: 5, count: 5, user_id: 456}],
      ...>   %User{id: 456}
      ...> )
      %{123 => 1}

  """
  @spec get_cprs([Pack.t()], User.t()) :: %{optional(Pack.id()) => float()}
  def get_cprs(packs, %User{id: user_id} = current_user) do
    original_counts = get_original_counts(packs, current_user)

    packs
    |> Enum.reject(fn %Pack{price_paid: price_paid, user_id: ^user_id} ->
      price_paid |> is_nil()
    end)
    |> Map.new(fn %{id: pack_id, price_paid: price_paid} ->
      {pack_id, calculate_cpr(price_paid, Map.fetch!(original_counts, pack_id))}
    end)
  end

  @spec calculate_cpr(price_paid :: float() | nil, count :: integer()) :: float() | nil
  defp calculate_cpr(nil, _count), do: nil
  defp calculate_cpr(_price_paid, 0), do: nil
  defp calculate_cpr(price_paid, total_count), do: price_paid / total_count

  @doc """
  Creates multiple packs at once.

  ## Examples

      iex> create_packs(%{field: value}, 3, %User{id: 123})
      {:ok, {3, [%Pack{}]}}

      iex> create_packs(%{field: bad_value}, 3, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec create_packs(attrs :: map(), multiplier :: non_neg_integer(), User.t()) ::
          {:ok, {count :: non_neg_integer(), [Pack.t()] | nil}}
          | {:error, Pack.changeset()}
  def create_packs(attrs, multiplier, %User{} = user) do
    attrs
    |> Map.new(fn {k, v} -> {to_string(k), v} end)
    |> do_create_packs(multiplier, user)
  end

  defp do_create_packs(
         %{"type_id" => type_id, "container_id" => container_id} = attrs,
         multiplier,
         user
       )
       when multiplier >= 1 and
              multiplier <= @pack_create_limit and
              type_id |> is_binary() and
              container_id |> is_binary() do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    changesets =
      Enum.map(1..multiplier, fn _count ->
        %Pack{}
        |> Pack.create_changeset(
          get_type!(type_id, user),
          Containers.get_container!(container_id, user),
          user,
          attrs
        )
      end)

    if changesets |> Enum.all?(fn %{valid?: valid} -> valid end) do
      {count, inserted_packs} =
        Repo.insert_all(
          Pack,
          changesets
          |> Enum.map(fn changeset ->
            changeset
            |> Map.get(:changes)
            |> Map.merge(%{inserted_at: now, updated_at: now})
          end),
          returning: true
        )

      {:ok, {count, inserted_packs |> preload_pack()}}
    else
      changesets
      |> Enum.reject(fn %{valid?: valid} -> valid end)
      |> List.first()
      |> Changeset.apply_action(:insert)
    end
  end

  defp do_create_packs(
         %{"type_id" => type_id, "container_id" => container_id} = attrs,
         _multiplier,
         user
       )
       when is_binary(type_id) and is_binary(container_id) do
    changeset =
      %Pack{}
      |> Pack.create_changeset(
        get_type!(type_id, user),
        Containers.get_container!(container_id, user),
        user,
        attrs
      )
      |> Changeset.add_error(:multiplier, dgettext("errors", "Invalid multiplier"))

    {:error, changeset}
  end

  defp do_create_packs(invalid_attrs, _multiplier, user) do
    {:error, %Pack{} |> Pack.create_changeset(nil, nil, user, invalid_attrs)}
  end

  @spec preload_pack(Pack.t()) :: Pack.t()
  @spec preload_pack([Pack.t()]) :: [Pack.t()]
  defp preload_pack(pack_or_packs) do
    pack_or_packs |> Repo.preload(@pack_preloads)
  end

  @doc """
  Updates a pack.

  ## Examples

      iex> update_pack(pack, %{field: new_value}, %User{id: 123})
      {:ok, %Pack{}}

      iex> update_pack(pack, %{field: bad_value}, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec update_pack(Pack.t(), attrs :: map(), User.t()) ::
          {:ok, Pack.t()} | {:error, Pack.changeset()}
  def update_pack(
        %Pack{user_id: user_id} = pack,
        attrs,
        %User{id: user_id} = user
      ) do
    pack
    |> Pack.update_changeset(attrs, user)
    |> Repo.update()
    |> case do
      {:ok, pack} -> {:ok, pack |> preload_pack()}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Deletes a pack.

  ## Examples

      iex> delete_pack(pack, %User{id: 123})
      {:ok, %Pack{}}

      iex> delete_pack(pack, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec delete_pack(Pack.t(), User.t()) ::
          {:ok, Pack.t()} | {:error, Pack.changeset()}
  def delete_pack(%Pack{user_id: user_id} = pack, %User{id: user_id}) do
    pack
    |> Repo.delete()
    |> case do
      {:ok, pack} -> {:ok, pack |> preload_pack()}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Deletes a pack.

  ## Examples

      iex> delete_pack!(pack, %User{id: 123})
      %Pack{}

  """
  @spec delete_pack!(Pack.t(), User.t()) :: Pack.t()
  def delete_pack!(pack, user) do
    {:ok, pack} = delete_pack(pack, user)
    pack
  end
end
