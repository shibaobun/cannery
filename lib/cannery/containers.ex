defmodule Cannery.Containers do
  @moduledoc """
  The Containers context.
  """

  import Ecto.Query, warn: false
  alias Cannery.{Containers.Container, Repo, Tags.Tag}
  alias Cannery.Containers.{Container, ContainerTag}
  alias Ecto.{Changeset}

  @doc """
  Returns the list of containers.

  ## Examples

      iex> list_containers()
      [%Container{}, ...]

  """
  @spec list_containers(user_or_user_id :: User.t() | User.id()) :: [Container.t()]
  def list_containers(%{id: user_id}), do: list_containers(user_id)
  def list_containers(user_id), do: Repo.all(from c in Container, where: c.user_id == ^user_id)

  @doc """
  Gets a single container.

  Raises `Ecto.NoResultsError` if the Container does not exist.

  ## Examples

      iex> get_container!(123)
      %Container{}

      iex> get_container!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_container!(Container.id()) :: Container.t()
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
  @spec update_container(Container.t() | Ecto.Changeset.t(), attrs :: map()) ::
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
  @spec change_container(Container.t() | Container.new_container()) :: Changeset.t()
  @spec change_container(Container.t() | Container.new_container(), attrs :: map()) ::
          Changeset.t()
  def change_container(container, attrs \\ %{}), do: container |> Container.changeset(attrs)

  @doc """
  Adds a tag to a container

  ## Examples

      iex> add_tag!(container, tag)
      %Container{}

      iex> add_tag!(container_id, tag_id)
      %Container{}
  """
  @spec add_tag!(Container.t(), Tag.t()) :: Container.t()
  def add_tag!(%{id: container_id}, %{id: tag_id}), do: add_tag!(container_id, tag_id)

  @spec add_tag!(Container.id(), Tag.id()) :: Container.t()
  def add_tag!(container_id, tag_id)
      when not (container_id |> is_nil()) and not (tag_id |> is_nil()) do
    %ContainerTag{}
    |> ContainerTag.changeset(%{"container_id" => container_id, "tag_id" => tag_id})
    |> Repo.insert!()
  end

  @doc """
  Removes a tag from a container

  ## Examples

      iex> remove_tag!(container, tag)
      %Container{}

      iex> remove_tag!(container_id, tag_id)
      %Container{}
  """
  @spec remove_tag!(Container.t(), Tag.t()) :: Container.t()
  def remove_tag!(%{id: container_id}, %{id: tag_id}), do: remove_tag!(container_id, tag_id)

  @spec remove_tag!(Container.id(), Tag.id()) :: Container.t()
  def remove_tag!(container_id, tag_id)
      when not (container_id |> is_nil()) and not (tag_id |> is_nil()) do
    Repo.delete_all(
      from ct in ContainerTag,
        where: ct.container_id == ^container_id,
        where: ct.tag_id == ^tag_id
    )
  end
end
