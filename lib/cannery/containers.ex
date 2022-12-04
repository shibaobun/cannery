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

      iex> list_containers("cool", %User{id: 123})
      [%Container{name: "my cool container"}, ...]

  """
  @spec list_containers(User.t()) :: [Container.t()]
  @spec list_containers(search :: nil | String.t(), User.t()) :: [Container.t()]
  def list_containers(search \\ nil, %User{id: user_id}) do
    from(c in Container,
      as: :c,
      left_join: t in assoc(c, :tags),
      as: :t,
      left_join: ag in assoc(c, :ammo_groups),
      as: :ag,
      where: c.user_id == ^user_id,
      order_by: c.name,
      preload: [tags: t, ammo_groups: ag]
    )
    |> list_containers_search(search)
    |> Repo.all()
  end

  defp list_containers_search(query, nil), do: query
  defp list_containers_search(query, ""), do: query

  defp list_containers_search(query, search) do
    trimmed_search = String.trim(search)

    query
    |> where(
      [c: c, t: t],
      fragment(
        "? @@ websearch_to_tsquery('english', ?)",
        c.search,
        ^trimmed_search
      ) or
        fragment(
          "? @@ websearch_to_tsquery('english', ?)",
          t.search,
          ^trimmed_search
        )
    )
    |> order_by(
      [c: c],
      desc:
        fragment(
          "ts_rank_cd(?, websearch_to_tsquery('english', ?), 4)",
          c.search,
          ^trimmed_search
        )
    )
  end

  @doc """
  Returns a count of containers.

  ## Examples

      iex> get_containers_count!(%User{id: 123})
      3

  """
  @spec get_containers_count!(User.t()) :: integer()
  def get_containers_count!(%User{id: user_id}) do
    Repo.one(
      from c in Container,
        where: c.user_id == ^user_id,
        select: count(c.id),
        distinct: true
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
          {:ok, Container.t()} | {:error, Container.changeset()}
  def create_container(attrs, %User{} = user) do
    %Container{} |> Container.create_changeset(user, attrs) |> Repo.insert()
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
          {:ok, Container.t()} | {:error, Container.changeset()}
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
          {:ok, Container.t()} | {:error, Container.changeset()}
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
        |> Container.update_changeset(%{})
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
  Adds a tag to a container

  ## Examples

      iex> add_tag!(container, tag, %User{id: 123})
      %Container{}

  """
  @spec add_tag!(Container.t(), Tag.t(), User.t()) :: ContainerTag.t()
  def add_tag!(
        %Container{user_id: user_id} = container,
        %Tag{user_id: user_id} = tag,
        %User{id: user_id}
      ),
      do: %ContainerTag{} |> ContainerTag.create_changeset(tag, container) |> Repo.insert!()

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
  @spec get_container_ammo_group_count!(Container.t()) :: non_neg_integer()
  def get_container_ammo_group_count!(%Container{} = container) do
    container
    |> Repo.preload(:ammo_groups)
    |> Map.fetch!(:ammo_groups)
    |> Enum.reject(fn %{count: count} -> count == 0 end)
    |> Enum.count()
  end

  @doc """
  Returns number of rounds in container. If data is already preloaded, then
  there will be no db hit.
  """
  @spec get_container_rounds!(Container.t()) :: non_neg_integer()
  def get_container_rounds!(%Container{} = container) do
    container
    |> Repo.preload(:ammo_groups)
    |> Map.fetch!(:ammo_groups)
    |> Enum.map(fn %{count: count} -> count end)
    |> Enum.sum()
  end
end
