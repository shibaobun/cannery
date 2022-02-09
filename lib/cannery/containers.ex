defmodule Cannery.Containers do
  @moduledoc """
  The Containers context.
  """

  import CanneryWeb.Gettext
  import Ecto.Query, warn: false
  alias Cannery.{Accounts.User, Ammo.AmmoGroup, Repo, Tags.Tag}
  alias Cannery.Containers.{Container, ContainerTag}
  alias Ecto.Changeset

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

      iex> create_container(%{field: value}, user)
      {:ok, %Container{}}

      iex> create_container(%{field: bad_value}, user)
      {:error, %Changeset{}}

  """
  @spec create_container(attrs :: map(), User.t()) ::
          {:ok, Container.t()} | {:error, Changeset.t(Container.new_container())}
  def create_container(attrs, %User{id: user_id}) do
    attrs = attrs |> Map.put("user_id", user_id)
    %Container{} |> Container.create_changeset(attrs) |> Repo.insert()
  end

  @doc """
  Updates a container.

  ## Examples

      iex> update_container(container, user, %{field: new_value})
      {:ok, %Container{}}

      iex> update_container(container, user, %{field: bad_value})
      {:error, %Changeset{}}

  """
  @spec update_container(Container.t(), User.t(), attrs :: map()) ::
          {:ok, Container.t()} | {:error, Changeset.t(Container.t())}
  def update_container(%Container{user_id: user_id} = container, %User{id: user_id}, attrs) do
    container |> Container.update_changeset(attrs) |> Repo.update()
  end

  @doc """
  Deletes a container.

  ## Examples

      iex> delete_container(container, user)
      {:ok, %Container{}}

      iex> delete_container(container, user)
      {:error, %Changeset{}}

  """
  @spec delete_container(Container.t(), User.t()) ::
          {:ok, Container.t()} | {:error, Changeset.t(Container.t())}
  def delete_container(%Container{user_id: user_id} = container, %User{id: user_id}) do
    Repo.one(
      from ag in AmmoGroup,
        where: ag.container_id == ^container.id,
        select: count(ag.id)
    )
    |> case do
      0 ->
        container |> Repo.delete()

      amount ->
        error_string =
          dngettext(
            "errors",
            "There is still %{amount} ammo group in this container!",
            "There are still %{amount} ammo groups in this container!",
            amount
          )

        container
        |> change_container()
        |> Changeset.add_error(
          :ammo_groups,
          error_string,
          amount: amount,
          count: amount
        )
        |> Changeset.apply_action(:delete)
    end
  end

  @doc """
  Deletes a container.

  ## Examples

      iex> delete_container(container, user)
      %Container{}

  """
  @spec delete_container!(Container.t(), User.t()) :: Container.t()
  def delete_container!(container, user) do
    {:ok, container} = container |> delete_container(user)
    container
  end

  @doc """
  Returns an `%Changeset{}` for tracking container changes.

  ## Examples

      iex> change_container(container)
      %Changeset{data: %Container{}}

      iex> change_container(%Changeset{})
      %Changeset{data: %Container{}}

  """
  @spec change_container(Container.t() | Container.new_container()) ::
          Changeset.t(Container.t() | Container.new_container())
  @spec change_container(Container.t() | Container.new_container(), attrs :: map()) ::
          Changeset.t(Container.t() | Container.new_container())
  def change_container(container, attrs \\ %{}),
    do: container |> Container.update_changeset(attrs)

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
