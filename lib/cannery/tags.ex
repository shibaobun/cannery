defmodule Cannery.Tags do
  @moduledoc """
  The Tags context.
  """

  import Ecto.Query, warn: false
  alias Cannery.{Accounts.User, Repo, Tags.Tag}
  alias Ecto.Changeset

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tags()
      [%Tag{}, ...]

  """
  @spec list_tags(User.t() | User.id()) :: [Tag.t()]
  def list_tags(%{id: user_id}), do: list_tags(user_id)
  def list_tags(user_id), do: Repo.all(from t in Tag, where: t.user_id == ^user_id)

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(123)
      %Tag{}

      iex> get_tag!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_tag!(Tag.id()) :: Tag.t()
  def get_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_tag(%{field: bad_value})
      {:error, %Changeset{}}

  """
  @spec create_tag(attrs :: map()) :: {:ok, Tag.t()} | {:error, Changeset.t(Tag.new_tag())}
  def create_tag(attrs), do: %Tag{} |> Tag.changeset(attrs) |> Repo.insert()

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(tag, %{field: bad_value})
      {:error, %Changeset{}}

  """
  @spec update_tag(Tag.t(), attrs :: map()) :: {:ok, Tag.t()} | {:error, Changeset.t(Tag.t())}
  def update_tag(tag, attrs), do: tag |> Tag.changeset(attrs) |> Repo.update()

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(tag)
      {:ok, %Tag{}}

      iex> delete_tag(tag)
      {:error, %Changeset{}}

  """
  @spec delete_tag(Tag.t()) :: {:ok, Tag.t()} | {:error, Changeset.t(Tag.t())}
  def delete_tag(tag), do: tag |> Repo.delete()

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag!(tag)
      %Tag{}

  """
  @spec delete_tag!(Tag.t()) :: Tag.t()
  def delete_tag!(tag), do: tag |> Repo.delete!()

  @doc """
  Returns an `%Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(tag)
      %Changeset{data: %Tag{}}

  """
  @spec change_tag(Tag.t() | Tag.new_tag()) :: Changeset.t(Tag.t() | Tag.new_tag())
  @spec change_tag(Tag.t() | Tag.new_tag(), attrs :: map()) ::
          Changeset.t(Tag.t() | Tag.new_tag())
  def change_tag(tag, attrs \\ %{}), do: Tag.changeset(tag, attrs)

  @doc """
  Get a random tag bg_color in `#ffffff` hex format

  ## Examples

      iex> random_color()
      "#cc0066"
  """
  @spec random_bg_color() :: <<_::7>>
  def random_bg_color do
    ["#cc0066", "#ff6699", "#6666ff", "#0066cc", "#00cc66", "#669900", "#ff9900", "#996633"]
    |> Enum.random()
  end
end
