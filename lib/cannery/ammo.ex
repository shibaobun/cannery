defmodule Cannery.Ammo do
  @moduledoc """
  The Ammo context.
  """

  import Ecto.Query, warn: false
  alias Cannery.Repo

  alias Cannery.Ammo.AmmoType

  @doc """
  Returns the list of ammo_types.

  ## Examples

      iex> list_ammo_types()
      [%AmmoType{}, ...]

  """
  def list_ammo_types do
    Repo.all(AmmoType)
  end

  @doc """
  Gets a single ammo_type.

  Raises `Ecto.NoResultsError` if the Ammo type does not exist.

  ## Examples

      iex> get_ammo_type!(123)
      %AmmoType{}

      iex> get_ammo_type!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ammo_type!(id), do: Repo.get!(AmmoType, id)

  @doc """
  Creates a ammo_type.

  ## Examples

      iex> create_ammo_type(%{field: value})
      {:ok, %AmmoType{}}

      iex> create_ammo_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ammo_type(attrs \\ %{}) do
    %AmmoType{}
    |> AmmoType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ammo_type.

  ## Examples

      iex> update_ammo_type(ammo_type, %{field: new_value})
      {:ok, %AmmoType{}}

      iex> update_ammo_type(ammo_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ammo_type(%AmmoType{} = ammo_type, attrs) do
    ammo_type
    |> AmmoType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ammo_type.

  ## Examples

      iex> delete_ammo_type(ammo_type)
      {:ok, %AmmoType{}}

      iex> delete_ammo_type(ammo_type)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ammo_type(%AmmoType{} = ammo_type) do
    Repo.delete(ammo_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ammo_type changes.

  ## Examples

      iex> change_ammo_type(ammo_type)
      %Ecto.Changeset{data: %AmmoType{}}

  """
  def change_ammo_type(%AmmoType{} = ammo_type, attrs \\ %{}) do
    AmmoType.changeset(ammo_type, attrs)
  end

  alias Cannery.Ammo.AmmoGroup

  @doc """
  Returns the list of ammo_groups.

  ## Examples

      iex> list_ammo_groups()
      [%AmmoGroup{}, ...]

  """
  def list_ammo_groups do
    Repo.all(AmmoGroup)
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
  def get_ammo_group!(id), do: Repo.get!(AmmoGroup, id)

  @doc """
  Creates a ammo_group.

  ## Examples

      iex> create_ammo_group(%{field: value})
      {:ok, %AmmoGroup{}}

      iex> create_ammo_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ammo_group(attrs \\ %{}) do
    %AmmoGroup{}
    |> AmmoGroup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ammo_group.

  ## Examples

      iex> update_ammo_group(ammo_group, %{field: new_value})
      {:ok, %AmmoGroup{}}

      iex> update_ammo_group(ammo_group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ammo_group(%AmmoGroup{} = ammo_group, attrs) do
    ammo_group
    |> AmmoGroup.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ammo_group.

  ## Examples

      iex> delete_ammo_group(ammo_group)
      {:ok, %AmmoGroup{}}

      iex> delete_ammo_group(ammo_group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ammo_group(%AmmoGroup{} = ammo_group) do
    Repo.delete(ammo_group)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ammo_group changes.

  ## Examples

      iex> change_ammo_group(ammo_group)
      %Ecto.Changeset{data: %AmmoGroup{}}

  """
  def change_ammo_group(%AmmoGroup{} = ammo_group, attrs \\ %{}) do
    AmmoGroup.changeset(ammo_group, attrs)
  end
end
