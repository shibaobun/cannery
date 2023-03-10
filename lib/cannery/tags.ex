defmodule Cannery.Tags do
  @moduledoc """
  The Tags context.
  """

  import Ecto.Query, warn: false
  import CanneryWeb.Gettext
  alias Cannery.{Accounts.User, Repo, Tags.Tag}

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
            "search @@ websearch_to_tsquery('english', ?)",
            ^trimmed_search
          ),
        order_by: {
          :desc,
          fragment(
            "ts_rank_cd(search, websearch_to_tsquery('english', ?), 4)",
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
      {:error, "tag not found"}

  """
  @spec get_tag(Tag.id(), User.t()) :: {:ok, Tag.t()} | {:error, String.t()}
  def get_tag(id, %User{id: user_id}) do
    Repo.one(from t in Tag, where: t.id == ^id and t.user_id == ^user_id)
    |> case do
      nil -> {:error, dgettext("errors", "Tag not found")}
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
  def get_tag!(id, %User{id: user_id}),
    do: Repo.one!(from t in Tag, where: t.id == ^id and t.user_id == ^user_id)

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
  def create_tag(attrs, %User{} = user),
    do: %Tag{} |> Tag.create_changeset(user, attrs) |> Repo.insert()

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
  def update_tag(%Tag{user_id: user_id} = tag, attrs, %User{id: user_id}),
    do: tag |> Tag.update_changeset(attrs) |> Repo.update()

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(tag, %User{id: 123})
      {:ok, %Tag{}}

      iex> delete_tag(tag, %User{id: 123})
      {:error, %Changeset{}}

  """
  @spec delete_tag(Tag.t(), User.t()) :: {:ok, Tag.t()} | {:error, Tag.changeset()}
  def delete_tag(%Tag{user_id: user_id} = tag, %User{id: user_id}), do: tag |> Repo.delete()

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag!(tag, %User{id: 123})
      %Tag{}

  """
  @spec delete_tag!(Tag.t(), User.t()) :: Tag.t()
  def delete_tag!(%Tag{user_id: user_id} = tag, %User{id: user_id}), do: tag |> Repo.delete!()
end
