defmodule Cannery.Containers.Container do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "containers" do
    field :desc, :string
    field :location, :string
    field :name, :string
    field :type, :string
    field :user_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(container, attrs) do
    container
    |> cast(attrs, [:name, :desc, :type, :location])
    |> validate_required([:name, :desc, :type, :location])
  end
end
