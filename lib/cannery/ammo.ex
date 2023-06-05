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

  @type list_types_option :: {:search, String.t() | nil} | {:class, Type.class() | :all}
  @type list_types_options :: [list_types_option()]

  @doc """
  Returns the list of types.

  ## Examples

      iex> list_types(%User{id: 123})
      [%Type{}, ...]

      iex> list_types(%User{id: 123}, search: "cool", class: :shotgun)
      [%Type{name: "My cool type", class: :shotgun}, ...]

  """
  @spec list_types(User.t()) :: [Type.t()]
  @spec list_types(User.t(), list_types_options()) :: [Type.t()]
  def list_types(%User{id: user_id}, opts \\ []) do
    from(t in Type,
      as: :t,
      where: t.user_id == ^user_id,
      preload: ^@type_preloads
    )
    |> list_types_filter_class(Keyword.get(opts, :class, :all))
    |> list_types_filter_search(Keyword.get(opts, :search))
    |> Repo.all()
  end

  @spec list_types_filter_search(Queryable.t(), search :: String.t() | nil) :: Queryable.t()
  defp list_types_filter_search(query, search) when search in ["", nil],
    do: query |> order_by([t: t], t.name)

  defp list_types_filter_search(query, search) when search |> is_binary() do
    trimmed_search = String.trim(search)

    query
    |> where(
      [t: t],
      fragment(
        "? @@ websearch_to_tsquery('english', ?)",
        t.search,
        ^trimmed_search
      )
    )
    |> order_by(
      [t: t],
      {
        :desc,
        fragment(
          "ts_rank_cd(?, websearch_to_tsquery('english', ?), 4)",
          t.search,
          ^trimmed_search
        )
      }
    )
  end

  @spec list_types_filter_class(Queryable.t(), Type.class() | :all) :: Queryable.t()
  defp list_types_filter_class(query, :rifle),
    do: query |> where([t: t], t.class == :rifle)

  defp list_types_filter_class(query, :pistol),
    do: query |> where([t: t], t.class == :pistol)

  defp list_types_filter_class(query, :shotgun),
    do: query |> where([t: t], t.class == :shotgun)

  defp list_types_filter_class(query, _all), do: query

  @doc """
  Returns a count of types.

  ## Examples

      iex> get_types_count!(%User{id: 123})
      3

  """
  @spec get_types_count!(User.t()) :: integer()
  def get_types_count!(%User{id: user_id}) do
    Repo.one(
      from t in Type,
        where: t.user_id == ^user_id,
        select: count(t.id),
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
      from t in Type,
        where: t.id == ^id,
        where: t.user_id == ^user_id,
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
      from p in Pack,
        as: :pack,
        left_join: sg_query in subquery(sg_total_query),
        on: p.id == sg_query.pack_id,
        where: p.type_id in ^type_ids,
        group_by: p.type_id,
        where: not (p.price_paid |> is_nil()),
        select: {p.type_id, sum(p.price_paid) / sum(p.count + coalesce(sg_query.total, 0))}
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
      from p in Pack,
        where: p.type_id in ^type_ids,
        where: p.user_id == ^user_id,
        group_by: p.type_id,
        select: {p.type_id, sum(p.count)}
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

  # Packs

  @type list_packs_option ::
          {:type_id, Type.id()}
          | {:container_id, Container.id()}
          | {:class, Type.class() | :all}
          | {:show_used, boolean() | nil}
          | {:search, String.t() | nil}
          | {:staged, boolean() | nil}
  @type list_packs_options :: [list_packs_option()]

  @doc """
  Returns the list of packs for a user and type.

  ## Examples

      iex> list_packs(%User{id: 456})
      [%Pack{}, ...]

      iex> list_packs(
      ...>   %User{id: 456},
      ...>   show_used: true,
      ...>   type_id: 123,
      ...>   container_id: 789,
      ...>   search: "something",
      ...>   staged: true
      ...> )
      [%Pack{}, %Pack{}, ...]

  """
  @spec list_packs(User.t()) :: [Pack.t()]
  @spec list_packs(User.t(), list_packs_options()) :: [Pack.t()]
  def list_packs(%User{id: user_id}, opts \\ []) do
    from(p in Pack,
      as: :p,
      join: t in assoc(p, :type),
      on: p.user_id == t.user_id,
      as: :t,
      join: c in Container,
      on: p.container_id == c.id,
      on: p.user_id == c.user_id,
      as: :c,
      where: p.user_id == c.user_id,
      left_join: ct in ContainerTag,
      on: c.id == ct.container_id,
      left_join: tag in Tag,
      on: ct.tag_id == tag.id,
      on: p.user_id == tag.user_id,
      as: :tag,
      where: p.user_id == ^user_id,
      distinct: p.id,
      preload: ^@pack_preloads
    )
    |> list_packs_search(Keyword.get(opts, :search))
    |> list_packs_class(Keyword.get(opts, :class, :all))
    |> list_packs_show_used(Keyword.get(opts, :show_used))
    |> list_packs_staged(Keyword.get(opts, :staged))
    |> list_packs_container_id(Keyword.get(opts, :container_id))
    |> list_packs_type_id(Keyword.get(opts, :type_id))
    |> Repo.all()
  end

  @spec list_packs_search(Queryable.t(), search :: String.t() | nil) :: Queryable.t()
  defp list_packs_search(query, search) when search in ["", nil], do: query

  defp list_packs_search(query, search) when search |> is_binary() do
    trimmed_search = String.trim(search)

    query
    |> where(
      [p: p, t: t, c: c, tag: tag],
      fragment(
        "? @@ websearch_to_tsquery('english', ?)",
        p.search,
        ^trimmed_search
      ) or
        fragment(
          "? @@ websearch_to_tsquery('english', ?)",
          t.search,
          ^trimmed_search
        ) or
        fragment(
          "? @@ websearch_to_tsquery('english', ?)",
          c.search,
          ^trimmed_search
        ) or
        fragment(
          "? @@ websearch_to_tsquery('english', ?)",
          tag.search,
          ^trimmed_search
        )
    )
    |> order_by(
      [p: p],
      desc:
        fragment(
          "ts_rank_cd(?, websearch_to_tsquery('english', ?), 4)",
          p.search,
          ^trimmed_search
        )
    )
  end

  @spec list_packs_class(Queryable.t(), Type.class() | :all) :: Queryable.t()
  defp list_packs_class(query, :rifle),
    do: query |> where([t: t], t.class == :rifle)

  defp list_packs_class(query, :pistol),
    do: query |> where([t: t], t.class == :pistol)

  defp list_packs_class(query, :shotgun),
    do: query |> where([t: t], t.class == :shotgun)

  defp list_packs_class(query, _all), do: query

  @spec list_packs_show_used(Queryable.t(), show_used :: boolean() | nil) :: Queryable.t()
  defp list_packs_show_used(query, true), do: query

  defp list_packs_show_used(query, _false),
    do: query |> where([p: p], not (p.count == 0))

  @spec list_packs_container_id(Queryable.t(), Container.id() | nil) :: Queryable.t()
  defp list_packs_container_id(query, container_id) when container_id |> is_binary(),
    do: query |> where([p: p], p.container_id == ^container_id)

  defp list_packs_container_id(query, _nil), do: query

  @spec list_packs_type_id(Queryable.t(), Type.id() | nil) :: Queryable.t()
  defp list_packs_type_id(query, type_id) when type_id |> is_binary(),
    do: query |> where([p: p], p.type_id == ^type_id)

  defp list_packs_type_id(query, _nil), do: query

  @spec list_packs_staged(Queryable.t(), staged :: boolean() | nil) :: Queryable.t()
  defp list_packs_staged(query, staged) when staged |> is_boolean(),
    do: query |> where([p: p], p.staged == ^staged)

  defp list_packs_staged(query, _nil), do: query

  @type get_packs_count_option ::
          {:container_id, Container.id() | nil}
          | {:type_id, Type.id() | nil}
          | {:show_used, :only_used | boolean() | nil}
  @type get_packs_count_options :: [get_packs_count_option()]

  @doc """
  Returns a count of packs.

  ## Examples

      iex> get_packs_count(%User{id: 123})
      3

      iex> get_packs_count(%User{id: 123}, show_used: true)
      4

      iex> get_packs_count(%User{id: 123}, container_id: 456)
      1

      iex> get_packs_count(%User{id: 123}, type_id: 456)
      2

  """
  @spec get_packs_count(User.t()) :: integer()
  @spec get_packs_count(User.t(), get_packs_count_options()) :: integer()
  def get_packs_count(%User{id: user_id}, opts \\ []) do
    from(p in Pack,
      as: :p,
      where: p.user_id == ^user_id,
      select: count(p.id),
      distinct: true
    )
    |> get_packs_count_show_used(Keyword.get(opts, :show_used))
    |> get_packs_count_container_id(Keyword.get(opts, :container_id))
    |> get_packs_count_type_id(Keyword.get(opts, :type_id))
    |> Repo.one() || 0
  end

  @spec get_packs_count_show_used(Queryable.t(), show_used :: :only_used | boolean() | nil) ::
          Queryable.t()
  defp get_packs_count_show_used(query, true), do: query

  defp get_packs_count_show_used(query, :only_used),
    do: query |> where([p: p], p.count == 0)

  defp get_packs_count_show_used(query, _false),
    do: query |> where([p: p], p.count > 0)

  @spec get_packs_count_type_id(Queryable.t(), Type.id() | nil) :: Queryable.t()
  defp get_packs_count_type_id(query, type_id) when type_id |> is_binary(),
    do: query |> where([p: p], p.type_id == ^type_id)

  defp get_packs_count_type_id(query, _nil), do: query

  @spec get_packs_count_container_id(Queryable.t(), Container.id() | nil) :: Queryable.t()
  defp get_packs_count_container_id(query, container_id) when container_id |> is_binary(),
    do: query |> where([p: p], p.container_id == ^container_id)

  defp get_packs_count_container_id(query, _nil), do: query

  @type get_grouped_packs_count_opt ::
          {:group_by, atom()}
          | {:containers, [Container.t()] | nil}
          | {:types, [Type.t()] | nil}
          | {:show_used, :only_used | boolean() | nil}
  @type get_grouped_packs_counts_opts :: [get_grouped_packs_count_opt()]

  @doc """
  Returns the count of packs for multiple types.

  ## Examples

      iex> get_grouped_packs_count(
      ...>   %User{id: 456},
      ...>   group_by: :type_id,
      ...>   types: [%Type{id: 123, user_id: 456}]
      ...> )
      3

      iex> get_grouped_packs_count(
      ...>   %User{id: 456},
      ...>   group_by: :type_id,
      ...>   types: [%Type{id: 123, user_id: 456}],
      ...>   show_used: true
      ...> )
      5

      iex> get_grouped_packs_count(
      ...>   %User{id: 456},
      ...>   group_by: :type_id,
      ...>   types: [%Type{id: 123, user_id: 456}],
      ...>   show_used: :only_used
      ...> )
      2

      iex> get_grouped_packs_count(
      ...>   %User{id: 456},
      ...>   group_by: :container_id,
      ...>   containers: [%Container{id: 123, user_id: 456}]
      ...> )
      7

  """
  @spec get_grouped_packs_count(User.t(), get_grouped_packs_counts_opts()) ::
          %{optional(Type.id() | Container.id()) => non_neg_integer()}
  def get_grouped_packs_count(%User{id: user_id}, opts) do
    from(p in Pack,
      as: :p,
      where: p.user_id == ^user_id
    )
    |> get_grouped_packs_count_group_by(Keyword.fetch!(opts, :group_by))
    |> get_grouped_packs_count_filter_ids(
      Keyword.fetch!(opts, :group_by),
      Keyword.get(opts, :types)
    )
    |> get_grouped_packs_count_filter_ids(
      Keyword.fetch!(opts, :group_by),
      Keyword.get(opts, :containers)
    )
    |> get_grouped_packs_count_show_used(Keyword.get(opts, :show_used))
    |> Repo.all()
    |> Map.new()
  end

  @spec get_grouped_packs_count_group_by(Queryable.t(), :type_id | :container_id) :: Queryable.t()
  defp get_grouped_packs_count_group_by(query, group_key) when group_key |> is_atom() do
    query
    |> group_by([p: p], field(p, ^group_key))
    |> select([p: p], {field(p, ^group_key), count(p.id)})
  end

  @spec get_grouped_packs_count_filter_ids(
          Queryable.t(),
          :type_id | :container_id,
          [Type.t()] | [Container.t()] | nil
        ) :: Queryable.t()
  defp get_grouped_packs_count_filter_ids(query, group_key, items) when items |> is_list() do
    item_ids = items |> Enum.map(fn %{id: id} -> id end)
    query |> where([p: p], field(p, ^group_key) in ^item_ids)
  end

  defp get_grouped_packs_count_filter_ids(query, _filter_key, _nil), do: query

  @spec get_grouped_packs_count_show_used(
          Queryable.t(),
          show_used :: :only_used | boolean() | nil
        ) :: Queryable.t()
  defp get_grouped_packs_count_show_used(query, true), do: query

  defp get_grouped_packs_count_show_used(query, :only_used) do
    query |> where([p: p], p.count == 0)
  end

  defp get_grouped_packs_count_show_used(query, _false) do
    query |> where([p: p], not (p.count == 0))
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
      from p in Pack,
        where: p.container_id in ^container_ids,
        group_by: p.container_id,
        select: {p.container_id, sum(p.count)}
    )
    |> Map.new()
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
      from p in Pack,
        where: p.id in ^ids,
        where: p.user_id == ^user_id,
        preload: ^@pack_preloads,
        select: {p.id, p}
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
