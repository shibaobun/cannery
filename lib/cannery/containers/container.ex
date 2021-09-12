defmodule Cannery.Containers.Container do
  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.{Accounts}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "containers" do
    field :name, :string
    field :desc, :string
    field :location, :string
    field :type, :string

    belongs_to :user, Accounts.User

    timestamps()
  end

  @type t :: %{
          id: Ecto.UUID.t(),
          name: String.t(),
          desc: String.t(),
          location: String.t(),
          type: String.t(),
          user: Accounts.User.t(),
          user_id: Ecto.UUID.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @doc false
  def changeset(container, attrs) do
    container
    |> cast(attrs, [:name, :desc, :type, :location, :user_id])
    |> validate_required([:name, :desc, :type, :location, :user_id])
  end
end
