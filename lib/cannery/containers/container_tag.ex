defmodule Cannery.Containers.ContainerTag do
  @moduledoc """
  Thru-table struct for associating Cannery.Containers.Container and
  Cannery.Tags.Tag.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.{Containers.Container, Containers.ContainerTag, Tags.Tag}
  alias Ecto.{Changeset, UUID}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "container_tags" do
    belongs_to :container, Container
    belongs_to :tag, Tag

    timestamps()
  end

  @type t :: %ContainerTag{
          id: id(),
          container: Container.t(),
          container_id: Container.id(),
          tag: Tag.t(),
          tag_id: Tag.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_container_tag :: %ContainerTag{}
  @type id :: UUID.t()

  @doc false
  @spec changeset(t() | new_container_tag(), attrs :: map()) ::
          Changeset.t(t() | new_container_tag())
  def changeset(container_tag, attrs) do
    container_tag
    |> cast(attrs, [:tag_id, :container_id])
    |> validate_required([:tag_id, :container_id])
  end
end
