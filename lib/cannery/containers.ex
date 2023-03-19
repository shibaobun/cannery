defmodule Cannery.Containers do
  @moduledoc """
  The Containers context.
  """

  import CanneryWeb.Gettext
  import Ecto.Query, warn: false
  alias Cannery.{Accounts.User, Ammo.AmmoGroup, Repo}
  alias Cannery.Containers.{Container, ContainerTag, Tag}
  alias Ecto.Changeset

  @container_preloads [:tags]

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
      where: c.user_id == ^user_id,
      order_by: c.name,
      preload: ^@container_preloads
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
        where: c.user_id == ^user_id,
        where: c.id == ^id,
        order_by: c.name,
        preload: ^@container_preloads
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
    %Container{}
    |> Container.create_changeset(user, attrs)
    |> Repo.insert()
    |> case do
      {:ok, container} -> {:ok, container |> preload_container()}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @spec preload_container(Container.t()) :: Container.t()
  @spec preload_container([Container.t()]) :: [Container.t()]
  def preload_container(container) do
    container |> Repo.preload(@container_preloads)
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
    container
    |> Container.update_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, container} -> {:ok, container |> preload_container()}
      {:error, changeset} -> {:error, changeset}
    end
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
        container
        |> Repo.delete()
        |> case do
          {:ok, container} -> {:ok, container |> preload_container()}
          {:error, changeset} -> {:error, changeset}
        end

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
      ) do
    %ContainerTag{}
    |> ContainerTag.create_changeset(tag, container)
    |> Repo.insert!()
  end

  @doc """
  Removes a tag from a container

  ## Examples

      iex> remove_tag!(container, tag, %User{id: 123})
      %Container{}

  """
  @spec remove_tag!(Container.t(), Tag.t(), User.t()) :: {non_neg_integer(), [ContainerTag.t()]}
  def remove_tag!(
        %Container{id: container_id, user_id: user_id},
        %Tag{id: tag_id, user_id: user_id},
        %User{id: user_id}
      ) do
    {count, results} =
      Repo.delete_all(
        from ct in ContainerTag,
          where: ct.container_id == ^container_id,
          where: ct.tag_id == ^tag_id,
          select: ct
      )

    if count == 0, do: raise("could not delete container tag"), else: {count, results}
  end

  # Container Tags

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tags(%User{id: 123})
      [%Tag{}, ...]

      iex> list_tags("cool", %User{id: 123})
      [%Tag{name: "my cool tag"}, ...]

  """
  @spec list_tags(User.t()) :: [Tag.t()]
  @spec list_tags(search :: nil | String.t(), User.t()) :: [Tag.t()]
  def list_tags(search \\ nil, user)

  def list_tags(search, %{id: user_id}) when search |> is_nil() or search == "",
    do: Repo.all(from t in Tag, where: t.user_id == ^user_id, order_by: t.name)

  def list_tags(search, %{id: user_id}) when search |> is_binary() do
    trimmed_search = String.trim(search)

    Repo.all(
      from t in Tag,
        where: t.user_id == ^user_id,
        where:
          fragment(
            "? @@ websearch_to_tsquery('english', ?)",
            t.search,
            ^trimmed_search
          ),
        order_by: {
          :desc,
          fragment(
            "ts_rank_cd(?, websearch_to_tsquery('english', ?), 4)",
            t.search,
            ^trimmed_search
          )
        }
    )
  end

  @doc """
  Gets a single tag.

  ## Examples

      iex> get_tag(123, %User{id: 123})
      {:ok, %Tag{}}

      iex> get_tag(456, %User{id: 123})
      {:error, :not_found}

  """
  @spec get_tag(Tag.id(), User.t()) :: {:ok, Tag.t()} | {:error, :not_found}
  def get_tag(id, %User{id: user_id}) do
    Repo.one(from t in Tag, where: t.id == ^id and t.user_id == ^user_id)
    |> case do
      nil -> {:error, :not_found}
      tag -> {:ok, tag}
    end
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(123, %User{id: 123})
      %Tag{}

      iex> get_tag!(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_tag!(Tag.id(), User.t()) :: Tag.t()
  def get_tag!(id, %User{id: user_id}) do
    Repo.one!(
      from t in Tag,
        where: t.id == ^id,
        where: t.user_id == ^user_id
    )
  end

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value}, %User{id: 123})
      {:ok, %Tag{}}

      iex> create_tag(%{field: bad_value}, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec create_tag(attrs :: map(), User.t()) ::
          {:ok, Tag.t()} | {:error, Tag.changeset()}
  def create_tag(attrs, %User{} = user) do
    %Tag{} |> Tag.create_changeset(user, attrs) |> Repo.insert()
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(tag, %{field: new_value}, %User{id: 123})
      {:ok, %Tag{}}

      iex> update_tag(tag, %{field: bad_value}, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec update_tag(Tag.t(), attrs :: map(), User.t()) ::
          {:ok, Tag.t()} | {:error, Tag.changeset()}
  def update_tag(%Tag{user_id: user_id} = tag, attrs, %User{id: user_id}) do
    tag |> Tag.update_changeset(attrs) |> Repo.update()
  end

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(tag, %User{id: 123})
      {:ok, %Tag{}}

      iex> delete_tag(tag, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec delete_tag(Tag.t(), User.t()) :: {:ok, Tag.t()} | {:error, Tag.changeset()}
  def delete_tag(%Tag{user_id: user_id} = tag, %User{id: user_id}) do
    tag |> Repo.delete()
  end

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag!(tag, %User{id: 123})
      %Tag{}

  """
  @spec delete_tag!(Tag.t(), User.t()) :: Tag.t()
  def delete_tag!(%Tag{user_id: user_id} = tag, %User{id: user_id}) do
    tag |> Repo.delete!()
  end
end
