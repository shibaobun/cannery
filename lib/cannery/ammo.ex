defmodule Cannery.Ammo do
  @moduledoc """
  The Ammo context.
  """

  import Ecto.Query, warn: false
  alias Cannery.{Accounts.User, Repo}
  alias Cannery.Ammo.{AmmoGroup, AmmoType}
  alias Ecto.Changeset

  @doc """
  Returns the list of ammo_types.

  ## Examples

      iex> list_ammo_types()
      [%AmmoType{}, ...]

  """
  @spec list_ammo_types() :: [AmmoType.t()]
  def list_ammo_types, do: Repo.all(AmmoType)

  @doc """
  Gets a single ammo_type.

  Raises `Ecto.NoResultsError` if the Ammo type does not exist.

  ## Examples

      iex> get_ammo_type!(123)
      %AmmoType{}

      iex> get_ammo_type!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_ammo_type!(AmmoType.id()) :: AmmoType.t()
  def get_ammo_type!(id), do: Repo.get!(AmmoType, id)

  @doc """
  Creates a ammo_type.

  ## Examples

      iex> create_ammo_type(%{field: value})
      {:ok, %AmmoType{}}

      iex> create_ammo_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_ammo_type(attrs :: map()) ::
          {:ok, AmmoType.t()} | {:error, Changeset.t(AmmoType.new_ammo_type())}
  def create_ammo_type(attrs \\ %{}),
    do: %AmmoType{} |> AmmoType.changeset(attrs) |> Repo.insert()

  @doc """
  Updates a ammo_type.

  ## Examples

      iex> update_ammo_type(ammo_type, %{field: new_value})
      {:ok, %AmmoType{}}

      iex> update_ammo_type(ammo_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_ammo_type(AmmoType.t(), attrs :: map()) ::
          {:ok, AmmoType.t()} | {:error, Changeset.t(AmmoType.t())}
  def update_ammo_type(%AmmoType{} = ammo_type, attrs),
    do: ammo_type |> AmmoType.changeset(attrs) |> Repo.update()

  @doc """
  Deletes a ammo_type.

  ## Examples

      iex> delete_ammo_type(ammo_type)
      {:ok, %AmmoType{}}

      iex> delete_ammo_type(ammo_type)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_ammo_type(AmmoType.t()) ::
          {:ok, AmmoType.t()} | {:error, Changeset.t(AmmoType.t())}
  def delete_ammo_type(%AmmoType{} = ammo_type), do: ammo_type |> Repo.delete()

  @doc """
  Deletes a ammo_type.

  ## Examples

      iex> delete_ammo_type(ammo_type)
      %AmmoType{}

  """
  @spec delete_ammo_type!(AmmoType.t()) :: AmmoType.t()
  def delete_ammo_type!(%AmmoType{} = ammo_type), do: ammo_type |> Repo.delete!()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ammo_type changes.

  ## Examples

      iex> change_ammo_type(ammo_type)
      %Ecto.Changeset{data: %AmmoType{}}

  """
  @spec change_ammo_type(AmmoType.t() | AmmoType.new_ammo_type()) ::
          Changeset.t(AmmoType.t() | AmmoType.new_ammo_type())
  @spec change_ammo_type(AmmoType.t() | AmmoType.new_ammo_type(), attrs :: map()) ::
          Changeset.t(AmmoType.t() | AmmoType.new_ammo_type())
  def change_ammo_type(%AmmoType{} = ammo_type, attrs \\ %{}),
    do: AmmoType.changeset(ammo_type, attrs)

  @doc """
  Returns the list of ammo_groups.

  ## Examples

      iex> list_ammo_groups(%User{id: 123})
      [%AmmoGroup{}, ...]

      iex> list_ammo_groups(123)
      [%AmmoGroup{}, ...]

  """
  @spec list_ammo_groups(User.t() | User.id()) :: [AmmoGroup.t()]
  def list_ammo_groups(%{id: user_id}), do: list_ammo_groups(user_id)

  def list_ammo_groups(user_id) do
    Repo.all(from am in AmmoGroup, where: am.user_id == ^user_id)
  end

  @doc """
  Gets a single ammo_group.

  Raises `Ecto.NoResultsError` if the Ammo group does not exist.

  ## Examples

      iex> get_ammo_group!(123)
      %AmmoGroup{}

      iex> get_ammo_group!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_ammo_group!(AmmoGroup.id()) :: AmmoGroup.t()
  def get_ammo_group!(id), do: Repo.get!(AmmoGroup, id)

  @doc """
  Creates a ammo_group.

  ## Examples

      iex> create_ammo_group(%{field: value})
      {:ok, %AmmoGroup{}}

      iex> create_ammo_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_ammo_group(attrs :: map()) ::
          {:ok, AmmoGroup.t()} | {:error, Changeset.t(AmmoGroup.new_ammo_group())}
  def create_ammo_group(attrs \\ %{}),
    do: %AmmoGroup{} |> AmmoGroup.changeset(attrs) |> Repo.insert()

  @doc """
  Updates a ammo_group.

  ## Examples

      iex> update_ammo_group(ammo_group, %{field: new_value})
      {:ok, %AmmoGroup{}}

      iex> update_ammo_group(ammo_group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_ammo_group(AmmoGroup.t(), attrs :: map()) ::
          {:ok, AmmoGroup.t()} | {:error, Changeset.t(AmmoGroup.t())}
  def update_ammo_group(%AmmoGroup{} = ammo_group, attrs),
    do: ammo_group |> AmmoGroup.changeset(attrs) |> Repo.update()

  @doc """
  Deletes a ammo_group.

  ## Examples

      iex> delete_ammo_group(ammo_group)
      {:ok, %AmmoGroup{}}

      iex> delete_ammo_group(ammo_group)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_ammo_group(AmmoGroup.t()) ::
          {:ok, AmmoGroup.t()} | {:error, Changeset.t(AmmoGroup.t())}
  def delete_ammo_group(%AmmoGroup{} = ammo_group), do: ammo_group |> Repo.delete()

  @doc """
  Deletes a ammo_group.

  ## Examples

      iex> delete_ammo_group!(ammo_group)
      %AmmoGroup{}

  """
  @spec delete_ammo_group!(AmmoGroup.t()) :: AmmoGroup.t()
  def delete_ammo_group!(%AmmoGroup{} = ammo_group), do: ammo_group |> Repo.delete!()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ammo_group changes.

  ## Examples

      iex> change_ammo_group(ammo_group)
      %Ecto.Changeset{data: %AmmoGroup{}}

  """
  @spec change_ammo_group(AmmoGroup.t()) :: Changeset.t(AmmoGroup.t())
  @spec change_ammo_group(AmmoGroup.t(), attrs :: map()) :: Changeset.t(AmmoGroup.t())
  def change_ammo_group(%AmmoGroup{} = ammo_group, attrs \\ %{}),
    do: AmmoGroup.changeset(ammo_group, attrs)
end
