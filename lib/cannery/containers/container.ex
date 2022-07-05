defmodule Cannery.Containers.Container do
  @moduledoc """
  A container that holds ammunition and belongs to a user.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.{Changeset, UUID}
  alias Cannery.Containers.{Container, ContainerTag}
  alias Cannery.{Accounts.User, Ammo.AmmoGroup, Tags.Tag}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "containers" do
    field :name, :string
    field :desc, :string
    field :location, :string
    field :type, :string

    belongs_to :user, User

    has_many :ammo_groups, AmmoGroup
    many_to_many :tags, Tag, join_through: ContainerTag

    timestamps()
  end

  @type t :: %Container{
          id: id(),
          name: String.t(),
          desc: String.t(),
          location: String.t(),
          type: String.t(),
          user: User.t(),
          user_id: User.id(),
          ammo_groups: [AmmoGroup.t()] | nil,
          tags: [Tag.t()] | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_container :: %Container{}
  @type id :: UUID.t()

  @doc false
  @spec create_changeset(new_container(), User.t(), attrs :: map()) ::
          Changeset.t(new_container())
  def create_changeset(container, %User{id: user_id}, attrs) do
    container
    |> change(user_id: user_id)
    |> cast(attrs, [:name, :desc, :type, :location])
    |> validate_required([:name, :type, :user_id])
  end

  @doc false
  @spec update_changeset(t() | new_container(), attrs :: map()) ::
          Changeset.t(t() | new_container())
  def update_changeset(container, attrs) do
    container
    |> cast(attrs, [:name, :desc, :type, :location])
    |> validate_required([:name, :type])
  end
end
