defmodule Cannery.Containers do
  @moduledoc """
  The Containers context.
  """

  import Ecto.Query, warn: false
  alias Cannery.{Containers.Container, Repo}
  alias Ecto.{Changeset, UUID}

  @doc """
  Returns the list of containers.

  ## Examples

      iex> list_containers()
      [%Container{}, ...]

  """
  @spec list_containers() :: [Container.t()]
  def list_containers do
    Repo.all(Container)
  end

  @doc """
  Gets a single container.

  Raises `Ecto.NoResultsError` if the Container does not exist.

  ## Examples

      iex> get_container!(123)
      %Container{}

      iex> get_container!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_container!(container_id :: UUID.t()) :: Container.t()
  def get_container!(id), do: Repo.get!(Container, id)

  @doc """
  Creates a container.

  ## Examples

      iex> create_container(%{field: value})
      {:ok, %Container{}}

      iex> create_container(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_container(attrs :: map()) :: {:ok, Container.t()} | {:error, Changeset.t()}
  def create_container(attrs) do
    %Container{} |> Container.changeset(attrs) |> Repo.insert()
  end

  @doc """
  Updates a container.

  ## Examples

      iex> update_container(container, %{field: new_value})
      {:ok, %Container{}}

      iex> update_container(container, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_container(Container.t() | Ecto.Changeset.t(), map()) ::
          {:ok, Container.t()} | {:error, Ecto.Changeset.t()}
  def update_container(container, attrs) do
    container |> Container.changeset(attrs) |> Repo.update()
  end

  @doc """
  Deletes a container.

  ## Examples

      iex> delete_container(container)
      {:ok, %Container{}}

      iex> delete_container(container)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_container(Container.t() | Ecto.Changeset.t()) ::
          {:ok, Container.t()} | {:error, Ecto.Changeset.t()}
  def delete_container(container), do: Repo.delete(container)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking container changes.

  ## Examples

      iex> change_container(container)
      %Ecto.Changeset{data: %Container{}}

      iex> change_container(%Ecto.Changeset{})
      %Ecto.Changeset{data: %Container{}}

  """
  @spec change_container(Container.t()) :: Changeset.t()
  @spec change_container(Container.t(), map()) :: Changeset.t()
  def change_container(container, attrs \\ %{}), do: container |> Container.changeset(attrs)
end
