defmodule Cannery.Containers.ContainerTag do
  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.{Containers, Tags}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "container_tags" do
    belongs_to :container, Containers.Container
    belongs_to :tag, Tags.Tag

    timestamps()
  end

  @type t :: %{
          id: Ecto.UUID.t(),
          container: Containers.Container.t(),
          container_id: Ecto.UUID.t(),
          tag: Tags.Tag.t(),
          tag_id: Ecto.UUID.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @doc false
  def changeset(container_tag, attrs) do
    container_tag
    |> cast(attrs, [:tag_id, :container_id])
    |> validate_required([:tag_id, :container_id])
  end
end
