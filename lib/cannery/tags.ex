defmodule Cannery.Tags do
  @moduledoc """
  The Tags context.
  """

  import Ecto.Query, warn: false
  alias Cannery.{Accounts, Repo}

  alias Cannery.Tags.Tag

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tags()
      [%Tag{}, ...]

  """
  @spec list_tags(Accounts.User.t()) :: [Tag.t()]
  def list_tags(%{id: user_id}) do
    list_tags(user_id)
  end

  def list_tags(user_id) do
    Repo.all(from t in Tag, where: t.user_id == ^user_id)
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(123)
      %Tag{}

      iex> get_tag!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_tag!(Ecto.UUID.t()) :: Tag.t()
  def get_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_tag(map()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def create_tag(attrs) do
    %Tag{} |> Tag.changeset(attrs) |> Repo.insert()
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_tag(Tag.t(), map()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def update_tag(tag, attrs) do
    tag |> Tag.changeset(attrs) |> Repo.update()
  end

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(tag)
      {:ok, %Tag{}}

      iex> delete_tag(tag)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_tag(Tag.t()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def delete_tag(tag) do
    Repo.delete(tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(tag)
      %Ecto.Changeset{data: %Tag{}}

  """
  @spec change_tag(Tag.t()) :: Ecto.Changeset.t()
  @spec change_tag(Tag.t(), map()) :: Ecto.Changeset.t()
  def change_tag(tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end

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
