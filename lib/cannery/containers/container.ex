defmodule Cannery.Containers.Container do
  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.{Accounts}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "containers" do
    field :desc, :string
    field :location, :string
    field :name, :string
    field :type, :string

    belongs_to :user, Accounts.User

    timestamps()
  end

  @doc false
  def changeset(container, attrs) do
    container
    |> cast(attrs, [:name, :desc, :type, :location, :user_id])
    |> validate_required([:name, :desc, :type, :location, :user_id])
  end
end
