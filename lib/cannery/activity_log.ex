defmodule Cannery.ActivityLog do
  @moduledoc """
  The ActivityLog context.
  """

  import Ecto.Query, warn: false
  alias Cannery.Ammo.{Pack, Type}
  alias Cannery.{Accounts.User, ActivityLog.ShotRecord, Repo}
  alias Ecto.{Multi, Queryable}

  @type list_shot_records_option ::
          {:search, String.t() | nil}
          | {:class, Type.class() | :all | nil}
          | {:pack_id, Pack.id() | nil}
  @type list_shot_records_options :: [list_shot_records_option()]

  @doc """
  Returns the list of shot_records.

  ## Examples

      iex> list_shot_records(%User{id: 123})
      [%ShotRecord{}, ...]

      iex> list_shot_records(%User{id: 123}, search: "cool")
      [%ShotRecord{notes: "My cool shot record"}, ...]

      iex> list_shot_records(%User{id: 123}, search: "cool", class: :rifle)
      [%ShotRecord{notes: "Shot some rifle rounds"}, ...]

      iex> list_shot_records(%User{id: 123}, pack_id: 456)
      [%ShotRecord{pack_id: 456}, ...]

  """
  @spec list_shot_records(User.t()) :: [ShotRecord.t()]
  @spec list_shot_records(User.t(), list_shot_records_options()) :: [ShotRecord.t()]
  def list_shot_records(%User{id: user_id}, opts \\ []) do
    from(sr in ShotRecord,
      as: :sr,
      left_join: p in Pack,
      as: :p,
      on: sr.pack_id == p.id,
      on: p.user_id == ^user_id,
      left_join: t in Type,
      as: :t,
      on: p.type_id == t.id,
      on: t.user_id == ^user_id,
      where: sr.user_id == ^user_id,
      distinct: sr.id
    )
    |> list_shot_records_search(Keyword.get(opts, :search))
    |> list_shot_records_class(Keyword.get(opts, :class))
    |> list_shot_records_pack_id(Keyword.get(opts, :pack_id))
    |> Repo.all()
  end

  @spec list_shot_records_search(Queryable.t(), search :: String.t() | nil) ::
          Queryable.t()
  defp list_shot_records_search(query, search) when search in ["", nil], do: query

  defp list_shot_records_search(query, search) when search |> is_binary() do
    trimmed_search = String.trim(search)

    query
    |> where(
      [sr: sr, p: p, t: t],
      fragment(
        "? @@ websearch_to_tsquery('english', ?)",
        sr.search,
        ^trimmed_search
      ) or
        fragment(
          "? @@ websearch_to_tsquery('english', ?)",
          p.search,
          ^trimmed_search
        ) or
        fragment(
          "? @@ websearch_to_tsquery('english', ?)",
          t.search,
          ^trimmed_search
        )
    )
    |> order_by([sr: sr], {
      :desc,
      fragment(
        "ts_rank_cd(?, websearch_to_tsquery('english', ?), 4)",
        sr.search,
        ^trimmed_search
      )
    })
  end

  @spec list_shot_records_class(Queryable.t(), Type.class() | :all | nil) :: Queryable.t()
  defp list_shot_records_class(query, class) when class in [:rifle, :pistol, :shotgun],
    do: query |> where([t: t], t.class == ^class)

  defp list_shot_records_class(query, _all), do: query

  @spec list_shot_records_pack_id(Queryable.t(), Pack.id() | nil) :: Queryable.t()
  defp list_shot_records_pack_id(query, pack_id) when pack_id |> is_binary(),
    do: query |> where([sr: sr], sr.pack_id == ^pack_id)

  defp list_shot_records_pack_id(query, _all), do: query

  @doc """
  Returns a count of shot records.

  ## Examples

      iex> get_shot_record_count!(%User{id: 123})
      3

  """
  @spec get_shot_record_count!(User.t()) :: integer()
  def get_shot_record_count!(%User{id: user_id}) do
    Repo.one(
      from sr in ShotRecord,
        where: sr.user_id == ^user_id,
        select: count(sr.id),
        distinct: true
    ) || 0
  end

  @doc """
  Gets a single shot_record.

  Raises `Ecto.NoResultsError` if the shot record does not exist.

  ## Examples

      iex> get_shot_record!(123, %User{id: 123})
      %ShotRecord{}

      iex> get_shot_record!(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_shot_record!(ShotRecord.id(), User.t()) :: ShotRecord.t()
  def get_shot_record!(id, %User{id: user_id}) do
    Repo.one!(
      from sr in ShotRecord,
        where: sr.id == ^id,
        where: sr.user_id == ^user_id,
        order_by: sr.date
    )
  end

  @doc """
  Creates a shot_record.

  ## Examples

      iex> create_shot_record(%{field: value}, %User{id: 123})
      {:ok, %ShotRecord{}}

      iex> create_shot_record(%{field: bad_value}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_shot_record(attrs :: map(), User.t(), Pack.t()) ::
          {:ok, ShotRecord.t()} | {:error, ShotRecord.changeset() | nil}
  def create_shot_record(attrs, user, pack) do
    Multi.new()
    |> Multi.insert(
      :create_shot_record,
      %ShotRecord{} |> ShotRecord.create_changeset(user, pack, attrs)
    )
    |> Multi.run(
      :pack,
      fn _repo, %{create_shot_record: %{pack_id: pack_id, user_id: user_id}} ->
        pack =
          Repo.one(
            from p in Pack,
              where: p.id == ^pack_id,
              where: p.user_id == ^user_id
          )

        {:ok, pack}
      end
    )
    |> Multi.update(
      :update_pack,
      fn %{create_shot_record: %{count: shot_record_count}, pack: %{count: pack_count}} ->
        pack |> Pack.range_changeset(%{"count" => pack_count - shot_record_count})
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{create_shot_record: shot_record}} -> {:ok, shot_record}
      {:error, :create_shot_record, changeset, _changes_so_far} -> {:error, changeset}
      {:error, _other_transaction, _value, _changes_so_far} -> {:error, nil}
    end
  end

  @doc """
  Updates a shot_record.

  ## Examples

      iex> update_shot_record(shot_record, %{field: new_value}, %User{id: 123})
      {:ok, %ShotRecord{}}

      iex> update_shot_record(shot_record, %{field: bad_value}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_shot_record(ShotRecord.t(), attrs :: map(), User.t()) ::
          {:ok, ShotRecord.t()} | {:error, ShotRecord.changeset() | nil}
  def update_shot_record(
        %ShotRecord{count: count, user_id: user_id} = shot_record,
        attrs,
        %User{id: user_id} = user
      ) do
    Multi.new()
    |> Multi.update(
      :update_shot_record,
      shot_record |> ShotRecord.update_changeset(user, attrs)
    )
    |> Multi.run(
      :pack,
      fn repo, %{update_shot_record: %{pack_id: pack_id, user_id: user_id}} ->
        {:ok, repo.one(from p in Pack, where: p.id == ^pack_id and p.user_id == ^user_id)}
      end
    )
    |> Multi.update(
      :update_pack,
      fn %{
           update_shot_record: %{count: new_count},
           pack: %{count: pack_count} = pack
         } ->
        shot_diff_to_add = new_count - count
        new_pack_count = pack_count - shot_diff_to_add
        pack |> Pack.range_changeset(%{"count" => new_pack_count})
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{update_shot_record: shot_record}} -> {:ok, shot_record}
      {:error, :update_shot_record, changeset, _changes_so_far} -> {:error, changeset}
      {:error, _other_transaction, _value, _changes_so_far} -> {:error, nil}
    end
  end

  @doc """
  Deletes a shot_record.

  ## Examples

      iex> delete_shot_record(shot_record, %User{id: 123})
      {:ok, %ShotRecord{}}

      iex> delete_shot_record(shot_record, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_shot_record(ShotRecord.t(), User.t()) ::
          {:ok, ShotRecord.t()} | {:error, ShotRecord.changeset()}
  def delete_shot_record(
        %ShotRecord{user_id: user_id} = shot_record,
        %User{id: user_id}
      ) do
    Multi.new()
    |> Multi.delete(:delete_shot_record, shot_record)
    |> Multi.run(
      :pack,
      fn repo, %{delete_shot_record: %{pack_id: pack_id, user_id: user_id}} ->
        {:ok, repo.one(from p in Pack, where: p.id == ^pack_id and p.user_id == ^user_id)}
      end
    )
    |> Multi.update(
      :update_pack,
      fn %{
           delete_shot_record: %{count: count},
           pack: %{count: pack_count} = pack
         } ->
        new_pack_count = pack_count + count
        pack |> Pack.range_changeset(%{"count" => new_pack_count})
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_shot_record: shot_record}} -> {:ok, shot_record}
      {:error, :delete_shot_record, changeset, _changes_so_far} -> {:error, changeset}
      {:error, _other_transaction, _value, _changes_so_far} -> {:error, nil}
    end
  end

  @doc """
  Returns the last entered shot record date for a pack
  """
  @spec get_last_used_date(Pack.t(), User.t()) :: Date.t() | nil
  def get_last_used_date(%Pack{id: pack_id} = pack, user) do
    [pack]
    |> get_last_used_dates(user)
    |> Map.get(pack_id)
  end

  @doc """
  Returns the last entered shot record date for a pack
  """
  @spec get_last_used_dates([Pack.t()], User.t()) :: %{optional(Pack.id()) => Date.t()}
  def get_last_used_dates(packs, %User{id: user_id}) do
    pack_ids =
      packs
      |> Enum.map(fn %Pack{id: pack_id, user_id: ^user_id} -> pack_id end)

    Repo.all(
      from sr in ShotRecord,
        where: sr.pack_id in ^pack_ids,
        where: sr.user_id == ^user_id,
        group_by: sr.pack_id,
        select: {sr.pack_id, max(sr.date)}
    )
    |> Map.new()
  end

  @type get_used_count_option :: {:pack_id, Pack.id() | nil} | {:type_id, Type.id() | nil}
  @type get_used_count_options :: [get_used_count_option()]

  @doc """
  Gets the total number of rounds shot for a type

  Raises `Ecto.NoResultsError` if the type does not exist.

  ## Examples

      iex> get_used_count(%User{id: 123}, type_id: 123)
      35

      iex> get_used_count(%User{id: 123}, pack_id: 456)
      50

  """
  @spec get_used_count(User.t(), get_used_count_options()) :: non_neg_integer()
  def get_used_count(%User{id: user_id}, opts) do
    from(sr in ShotRecord,
      as: :sr,
      left_join: p in Pack,
      on: sr.pack_id == p.id,
      on: p.user_id == ^user_id,
      as: :p,
      where: sr.user_id == ^user_id,
      where: not (sr.count |> is_nil()),
      select: sum(sr.count),
      distinct: true
    )
    |> get_used_count_type_id(Keyword.get(opts, :type_id))
    |> get_used_count_pack_id(Keyword.get(opts, :pack_id))
    |> Repo.one() || 0
  end

  @spec get_used_count_pack_id(Queryable.t(), Pack.id() | nil) :: Queryable.t()
  defp get_used_count_pack_id(query, pack_id) when pack_id |> is_binary() do
    query |> where([sr: sr], sr.pack_id == ^pack_id)
  end

  defp get_used_count_pack_id(query, _nil), do: query

  @spec get_used_count_type_id(Queryable.t(), Type.id() | nil) :: Queryable.t()
  defp get_used_count_type_id(query, type_id) when type_id |> is_binary() do
    query |> where([p: p], p.type_id == ^type_id)
  end

  defp get_used_count_type_id(query, _nil), do: query

  @type get_grouped_used_counts_option ::
          {:packs, [Pack.t()] | nil}
          | {:types, [Type.t()] | nil}
          | {:group_by, :type_id | :pack_id}
  @type get_grouped_used_counts_options :: [get_grouped_used_counts_option()]

  @doc """
  Gets the total number of rounds shot for multiple types or packs

  ## Examples

      iex> get_grouped_used_counts(
      ...>   %User{id: 123},
      ...>   group_by: :type_id,
      ...>   types: [%Type{id: 456, user_id: 123}]
      ...> )
      35

      iex> get_grouped_used_counts(
      ...>   %User{id: 123},
      ...>   group_by: :pack_id,
      ...>   packs: [%Pack{id: 456, user_id: 123}]
      ...> )
      22

  """
  @spec get_grouped_used_counts(User.t(), get_grouped_used_counts_options()) ::
          %{optional(Type.id() | Pack.id()) => non_neg_integer()}
  def get_grouped_used_counts(%User{id: user_id}, opts) do
    from(p in Pack,
      as: :p,
      left_join: sr in ShotRecord,
      on: p.id == sr.pack_id,
      on: p.user_id == ^user_id,
      as: :sr,
      where: sr.user_id == ^user_id,
      where: not (sr.count |> is_nil())
    )
    |> get_grouped_used_counts_group_by(Keyword.fetch!(opts, :group_by))
    |> get_grouped_used_counts_types(Keyword.get(opts, :types))
    |> get_grouped_used_counts_packs(Keyword.get(opts, :packs))
    |> Repo.all()
    |> Map.new()
  end

  @spec get_grouped_used_counts_group_by(Queryable.t(), :type_id | :pack_id) :: Queryable.t()
  defp get_grouped_used_counts_group_by(query, :type_id) do
    query
    |> group_by([p: p], p.type_id)
    |> select([sr: sr, p: p], {p.type_id, sum(sr.count)})
  end

  defp get_grouped_used_counts_group_by(query, :pack_id) do
    query
    |> group_by([sr: sr], sr.pack_id)
    |> select([sr: sr], {sr.pack_id, sum(sr.count)})
  end

  @spec get_grouped_used_counts_types(Queryable.t(), [Type.t()] | nil) :: Queryable.t()
  defp get_grouped_used_counts_types(query, types) when types |> is_list() do
    type_ids = types |> Enum.map(fn %Type{id: type_id} -> type_id end)
    query |> where([p: p], p.type_id in ^type_ids)
  end

  defp get_grouped_used_counts_types(query, _nil), do: query

  @spec get_grouped_used_counts_packs(Queryable.t(), [Pack.t()] | nil) :: Queryable.t()
  defp get_grouped_used_counts_packs(query, packs) when packs |> is_list() do
    pack_ids = packs |> Enum.map(fn %Pack{id: pack_id} -> pack_id end)
    query |> where([p: p], p.id in ^pack_ids)
  end

  defp get_grouped_used_counts_packs(query, _nil), do: query
end
