defmodule Cannery.Ammo do
  @moduledoc """
  The Ammo context.
  """

  import Ecto.Query, warn: false
  alias Cannery.{Accounts.User, Containers, Repo}
  alias Cannery.Ammo.{AmmoGroup, AmmoType}
  alias Ecto.Changeset

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

  Raises `Ecto.NoResultsError` if the Ammo type does not exist.

  ## Examples

      iex> get_ammo_type!(123, %User{id: 123})
      %AmmoType{}

      iex> get_ammo_type!(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_average_cost_for_ammo_type!(AmmoType.t(), User.t()) :: float()
  def get_average_cost_for_ammo_type!(
        %AmmoType{id: ammo_type_id, user_id: user_id},
        %User{id: user_id}
      ) do
    Repo.one!(
      from ag in AmmoGroup,
        left_join: sg in assoc(ag, :shot_groups),
        where: ag.ammo_type_id == ^ammo_type_id,
        where: not (ag.price_paid |> is_nil()),
        select: sum(ag.price_paid) / (sum(ag.count) + sum(sg.count))
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
    )
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
    )
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
  def create_ammo_type(attrs \\ %{}, %User{id: user_id}) do
    %AmmoType{}
    |> AmmoType.create_changeset(attrs |> Map.put("user_id", user_id))
    |> Repo.insert()
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
  Returns an `%Changeset{}` for tracking ammo_type changes.

  ## Examples

      iex> change_ammo_type(ammo_type)
      %Changeset{data: %AmmoType{}}

  """
  @spec change_ammo_type(AmmoType.t() | AmmoType.new_ammo_type()) ::
          Changeset.t(AmmoType.t() | AmmoType.new_ammo_type())
  @spec change_ammo_type(AmmoType.t() | AmmoType.new_ammo_type(), attrs :: map()) ::
          Changeset.t(AmmoType.t() | AmmoType.new_ammo_type())
  def change_ammo_type(%AmmoType{} = ammo_type, attrs \\ %{}),
    do: AmmoType.update_changeset(ammo_type, attrs)

  @doc """
  Returns the list of ammo_groups for a user and type.

  ## Examples

      iex> list_ammo_groups_for_type(%AmmoType{id: 123}, %User{id: 123})
      [%AmmoGroup{}, ...]

  """
  @spec list_ammo_groups_for_type(AmmoType.t(), User.t()) :: [AmmoGroup.t()]
  def list_ammo_groups_for_type(%AmmoType{id: ammo_type_id, user_id: user_id}, %User{id: user_id}) do
    Repo.all(
      from ag in AmmoGroup,
        left_join: sg in assoc(ag, :shot_groups),
        where: ag.ammo_type_id == ^ammo_type_id,
        where: ag.user_id == ^user_id,
        preload: [shot_groups: sg],
        order_by: ag.id
    )
  end

  @doc """
  Returns the list of ammo_groups for a user.

  ## Examples

      iex> list_ammo_groups(%User{id: 123})
      [%AmmoGroup{}, ...]

  """
  @spec list_ammo_groups(User.t()) :: [AmmoGroup.t()]
  @spec list_ammo_groups(User.t(), include_empty :: boolean()) :: [AmmoGroup.t()]
  def list_ammo_groups(%User{id: user_id}, include_empty \\ false) do
    if include_empty do
      from ag in AmmoGroup,
        left_join: sg in assoc(ag, :shot_groups),
        where: ag.user_id == ^user_id,
        preload: [shot_groups: sg],
        order_by: ag.id
    else
      from ag in AmmoGroup,
        left_join: sg in assoc(ag, :shot_groups),
        where: ag.user_id == ^user_id,
        where: not (ag.count == 0),
        preload: [shot_groups: sg],
        order_by: ag.id
    end
    |> Repo.all()
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
    |> Map.get(:shot_groups)
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
  Creates a ammo_group.

  ## Examples

      iex> create_ammo_group(%{field: value}, %User{id: 123})
      {:ok, %AmmoGroup{}}

      iex> create_ammo_group(%{field: bad_value}, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec create_ammo_group(attrs :: map(), User.t()) ::
          {:ok, AmmoGroup.t()} | {:error, Changeset.t(AmmoGroup.new_ammo_group())}
  def create_ammo_group(
        %{"ammo_type_id" => ammo_type_id, "container_id" => container_id} = attrs,
        %User{id: user_id} = user
      ) do
    # validate ammo type and container ids belong to user
    _valid_ammo_type = get_ammo_type!(ammo_type_id, user)
    _valid_container = Containers.get_container!(container_id, user)

    %AmmoGroup{}
    |> AmmoGroup.create_changeset(attrs |> Map.put("user_id", user_id))
    |> Repo.insert()
  end

  def create_ammo_group(invalid_attrs, _user) do
    %AmmoGroup{}
    |> AmmoGroup.create_changeset(invalid_attrs |> Map.put("user_id", "-1"))
    |> Repo.insert()
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

  @doc """
  Returns an `%Changeset{}` for tracking ammo_group changes.

  ## Examples

      iex> change_ammo_group(ammo_group)
      %Changeset{data: %AmmoGroup{}}

  """
  @spec change_ammo_group(AmmoGroup.t()) :: Changeset.t(AmmoGroup.t())
  @spec change_ammo_group(AmmoGroup.t(), attrs :: map()) :: Changeset.t(AmmoGroup.t())
  def change_ammo_group(%AmmoGroup{} = ammo_group, attrs \\ %{}),
    do: AmmoGroup.update_changeset(ammo_group, attrs)
end
