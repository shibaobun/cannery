defmodule Cannery.Containers.ContainerTag do
  @moduledoc """
  Thru-table struct for associating Cannery.Containers.Container and
  Cannery.Tags.Tag.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.{Containers.Container, Containers.ContainerTag, Tags.Tag}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "container_tags" do
    belongs_to :container, Container
    belongs_to :tag, Tag

    timestamps()
  end

  @type t :: %ContainerTag{
          id: Ecto.UUID.t(),
          container: Container.t(),
          container_id: Ecto.UUID.t(),
          tag: Tag.t(),
          tag_id: Ecto.UUID.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @doc false
  @spec changeset(ContainerTag.t(), map()) :: Ecto.Changeset.t()
  def changeset(container_tag, attrs) do
    container_tag
    |> cast(attrs, [:tag_id, :container_id])
    |> validate_required([:tag_id, :container_id])
  end
end
