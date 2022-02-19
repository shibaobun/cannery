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

      iex> list_containers(%User{id: 123})
      [%Container{}, ...]

  """
  @spec list_containers(User.t()) :: [Container.t()]
  def list_containers(%User{id: user_id}) do
    Repo.all(
      from c in Container,
        left_join: t in assoc(c, :tags),
        left_join: ag in assoc(c, :ammo_groups),
        where: c.user_id == ^user_id,
        order_by: c.name,
        preload: [tags: t, ammo_groups: ag]
    )
  end

  @doc """
  Gets a single container.

  Raises `Ecto.NoResultsError` if the Container does not exist.

  ## Examples

      iex> get_container!(123, %User{id: 123})
      %Container{}

      iex> get_container!(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_container!(Container.id(), User.t()) :: Container.t()
  def get_container!(id, %User{id: user_id}) do
    Repo.one!(
      from c in Container,
        left_join: t in assoc(c, :tags),
        left_join: ag in assoc(c, :ammo_groups),
        where: c.user_id == ^user_id,
        where: c.id == ^id,
        order_by: c.name,
        preload: [tags: t, ammo_groups: ag]
    )
  end

  @doc """
  Creates a container.

  ## Examples

      iex> create_container(%{field: value}, %User{id: 123})
      {:ok, %Container{}}

      iex> create_container(%{field: bad_value}, %User{id: 123})
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

      iex> update_container(container, %User{id: 123}, %{field: new_value})
      {:ok, %Container{}}

      iex> update_container(container, %User{id: 123}, %{field: bad_value})
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

      iex> delete_container(container, %User{id: 123})
      {:ok, %Container{}}

      iex> delete_container(container, %User{id: 123})
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

      _amount ->
        error = dgettext("errors", "Container must be empty before deleting")

        container
        |> change_container()
        |> Changeset.add_error(:ammo_groups, error)
        |> Changeset.apply_action(:delete)
    end
  end

  @doc """
  Deletes a container.

  ## Examples

      iex> delete_container(container, %User{id: 123})
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

      iex> add_tag!(container, tag, %User{id: 123})
      %Container{}

  """
  @spec add_tag!(Container.t(), Tag.t(), User.t()) :: ContainerTag.t()
  def add_tag!(
        %Container{id: container_id, user_id: user_id},
        %Tag{id: tag_id, user_id: user_id},
        %User{id: user_id}
      ) do
    %ContainerTag{}
    |> ContainerTag.changeset(%{"container_id" => container_id, "tag_id" => tag_id})
    |> Repo.insert!()
  end

  @doc """
  Removes a tag from a container

  ## Examples

      iex> remove_tag!(container, tag, %User{id: 123})
      %Container{}

  """
  @spec remove_tag!(Container.t(), Tag.t(), User.t()) :: non_neg_integer()
  def remove_tag!(
        %Container{id: container_id, user_id: user_id},
        %Tag{id: tag_id, user_id: user_id},
        %User{id: user_id}
      ) do
    {count, _} =
      Repo.delete_all(
        from ct in ContainerTag,
          where: ct.container_id == ^container_id,
          where: ct.tag_id == ^tag_id
      )

    if count == 0, do: raise("could not delete container tag"), else: count
  end

  @doc """
  Returns number of rounds in container. If data is already preloaded, then
  there will be no db hit.
  """
  @spec get_container_rounds!(Container.t()) :: non_neg_integer()
  def get_container_rounds!(%Container{} = container) do
    container
    |> Repo.preload(:ammo_groups)
    |> Map.get(:ammo_groups)
    |> Enum.map(fn %{count: count} -> count end)
    |> Enum.sum()
  end
end
