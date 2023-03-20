defmodule Cannery.Containers.Container do
  @moduledoc """
  A container that holds ammunition and belongs to a user.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.{Changeset, UUID}
  alias Cannery.{Accounts.User, Containers.ContainerTag, Containers.Tag}

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :desc,
             :location,
             :type,
             :tags
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "containers" do
    field :name, :string
    field :desc, :string
    field :location, :string
    field :type, :string

    field :user_id, :binary_id

    many_to_many :tags, Tag, join_through: ContainerTag

    timestamps()
  end

  @type t :: %__MODULE__{
          id: id(),
          name: String.t(),
          desc: String.t(),
          location: String.t(),
          type: String.t(),
          user_id: User.id(),
          tags: [Tag.t()] | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_container :: %__MODULE__{}
  @type id :: UUID.t()
  @type changeset :: Changeset.t(t() | new_container())

  @doc false
  @spec create_changeset(new_container(), User.t(), attrs :: map()) :: changeset()
  def create_changeset(container, %User{id: user_id}, attrs) do
    container
    |> change(user_id: user_id)
    |> cast(attrs, [:name, :desc, :type, :location])
    |> validate_length(:name, max: 255)
    |> validate_length(:type, max: 255)
    |> validate_required([:name, :type, :user_id])
  end

  @doc false
  @spec update_changeset(t() | new_container(), attrs :: map()) :: changeset()
  def update_changeset(container, attrs) do
    container
    |> cast(attrs, [:name, :desc, :type, :location])
    |> validate_length(:name, max: 255)
    |> validate_length(:type, max: 255)
    |> validate_required([:name, :type])
  end
end
