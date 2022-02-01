defmodule Cannery.Containers.Container do
  @moduledoc """
  A container that holds ammunition and belongs to a user.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.{Changeset, UUID}
  alias Cannery.{Accounts.User, Containers.Container}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "containers" do
    field :name, :string
    field :desc, :string
    field :location, :string
    field :type, :string

    belongs_to :user, User

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
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_container :: %Container{}
  @type id :: UUID.t()

  @doc false
  @spec changeset(t() | new_container(), attrs :: map()) :: Changeset.t()
  def changeset(container, attrs) do
    container
    |> cast(attrs, [:name, :desc, :type, :location, :user_id])
    |> validate_required([:name, :type, :user_id])
  end
end
