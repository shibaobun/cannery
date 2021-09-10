defmodule Cannery.Invites.Invite do
  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.{Accounts}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "invites" do
    field :name, :string
    field :token, :string
    field :uses_left, :integer, default: nil
    field :disabled_at, :naive_datetime
    belongs_to :user, Accounts.User

    timestamps()
  end

  @doc false
  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:name, :token, :uses_left, :disabled_at, :user_id])
    |> validate_required([:name, :token, :user_id])
  end

  @type t :: %{
          id: Ecto.UUID.t(),
          name: String.t(),
          token: String.t(),
          uses_left: integer() | nil,
          disabled_at: NaiveDateTime.t(),
          user_id: Ecto.UUID.t(),
          user: Accounts.User.t()
        }
end
