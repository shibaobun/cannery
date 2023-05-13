defmodule Cannery.ActivityLog do
  @moduledoc """
  The ActivityLog context.
  """

  import Ecto.Query, warn: false
  alias Cannery.Ammo.{Pack, Type}
  alias Cannery.{Accounts.User, ActivityLog.ShotRecord, Repo}
  alias Ecto.{Multi, Queryable}

  @doc """
  Returns the list of shot_records.

  ## Examples

      iex> list_shot_records(:all, %User{id: 123})
      [%ShotRecord{}, ...]

      iex> list_shot_records("cool", :all, %User{id: 123})
      [%ShotRecord{notes: "My cool shot record"}, ...]

      iex> list_shot_records("cool", :rifle, %User{id: 123})
      [%ShotRecord{notes: "Shot some rifle rounds"}, ...]

  """
  @spec list_shot_records(Type.class() | :all, User.t()) :: [ShotRecord.t()]
  @spec list_shot_records(search :: nil | String.t(), Type.class() | :all, User.t()) ::
          [ShotRecord.t()]
  def list_shot_records(search \\ nil, type, %{id: user_id}) do
    from(sg in ShotRecord,
      as: :sg,
      left_join: p in Pack,
      as: :p,
      on: sg.pack_id == p.id,
      left_join: at in Type,
      as: :at,
      on: p.type_id == at.id,
      where: sg.user_id == ^user_id,
      distinct: sg.id
    )
    |> list_shot_records_search(search)
    |> list_shot_records_filter_type(type)
    |> Repo.all()
  end

  @spec list_shot_records_search(Queryable.t(), search :: String.t() | nil) ::
          Queryable.t()
  defp list_shot_records_search(query, search) when search in ["", nil], do: query

  defp list_shot_records_search(query, search) when search |> is_binary() do
    trimmed_search = String.trim(search)

    query
    |> where(
      [sg: sg, p: p, at: at],
      fragment(
        "? @@ websearch_to_tsquery('english', ?)",
        sg.search,
        ^trimmed_search
      ) or
        fragment(
          "? @@ websearch_to_tsquery('english', ?)",
          p.search,
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

  @spec list_shot_records_filter_type(Queryable.t(), Type.class() | :all) ::
          Queryable.t()
  defp list_shot_records_filter_type(query, :rifle),
    do: query |> where([at: at], at.class == :rifle)

  defp list_shot_records_filter_type(query, :pistol),
    do: query |> where([at: at], at.class == :pistol)

  defp list_shot_records_filter_type(query, :shotgun),
    do: query |> where([at: at], at.class == :shotgun)

  defp list_shot_records_filter_type(query, _all), do: query

  @doc """
  Returns a count of shot records.

  ## Examples

      iex> get_shot_record_count!(%User{id: 123})
      3

  """
  @spec get_shot_record_count!(User.t()) :: integer()
  def get_shot_record_count!(%User{id: user_id}) do
    Repo.one(
      from sg in ShotRecord,
        where: sg.user_id == ^user_id,
        select: count(sg.id),
        distinct: true
    ) || 0
  end

  @spec list_shot_records_for_pack(Pack.t(), User.t()) :: [ShotRecord.t()]
  def list_shot_records_for_pack(
        %Pack{id: pack_id, user_id: user_id},
        %User{id: user_id}
      ) do
    Repo.all(
      from sg in ShotRecord,
        where: sg.pack_id == ^pack_id,
        where: sg.user_id == ^user_id
    )
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
      from sg in ShotRecord,
        where: sg.id == ^id,
        where: sg.user_id == ^user_id,
        order_by: sg.date
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
  Returns the number of shot rounds for a pack
  """
  @spec get_used_count(Pack.t(), User.t()) :: non_neg_integer()
  def get_used_count(%Pack{id: pack_id} = pack, user) do
    [pack]
    |> get_used_counts(user)
    |> Map.get(pack_id, 0)
  end

  @doc """
  Returns the number of shot rounds for multiple packs
  """
  @spec get_used_counts([Pack.t()], User.t()) ::
          %{optional(Pack.id()) => non_neg_integer()}
  def get_used_counts(packs, %User{id: user_id}) do
    pack_ids =
      packs
      |> Enum.map(fn %{id: pack_id} -> pack_id end)

    Repo.all(
      from sg in ShotRecord,
        where: sg.pack_id in ^pack_ids,
        where: sg.user_id == ^user_id,
        group_by: sg.pack_id,
        select: {sg.pack_id, sum(sg.count)}
    )
    |> Map.new()
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
      from sg in ShotRecord,
        where: sg.pack_id in ^pack_ids,
        where: sg.user_id == ^user_id,
        group_by: sg.pack_id,
        select: {sg.pack_id, max(sg.date)}
    )
    |> Map.new()
  end

  @doc """
  Gets the total number of rounds shot for a type

  Raises `Ecto.NoResultsError` if the type does not exist.

  ## Examples

      iex> get_used_count_for_type(123, %User{id: 123})
      35

      iex> get_used_count_for_type(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_used_count_for_type(Type.t(), User.t()) :: non_neg_integer()
  def get_used_count_for_type(%Type{id: type_id} = type, user) do
    [type]
    |> get_used_count_for_types(user)
    |> Map.get(type_id, 0)
  end

  @doc """
  Gets the total number of rounds shot for multiple types

  ## Examples

      iex> get_used_count_for_types(123, %User{id: 123})
      35

  """
  @spec get_used_count_for_types([Type.t()], User.t()) ::
          %{optional(Type.id()) => non_neg_integer()}
  def get_used_count_for_types(types, %User{id: user_id}) do
    type_ids =
      types
      |> Enum.map(fn %Type{id: type_id, user_id: ^user_id} -> type_id end)

    Repo.all(
      from p in Pack,
        left_join: sg in ShotRecord,
        on: p.id == sg.pack_id,
        where: p.type_id in ^type_ids,
        where: not (sg.count |> is_nil()),
        group_by: p.type_id,
        select: {p.type_id, sum(sg.count)}
    )
    |> Map.new()
  end
end
