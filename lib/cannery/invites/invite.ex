defmodule Cannery.Invites.Invite do
  @moduledoc """
  An invite, created by an admin to allow someone to join their instance. An
  invite can be enabled or disabled, and can have an optional number of uses if
  `:uses_left` is defined.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.{Changeset, UUID}
  alias Cannery.{Accounts.User, Invites.Invite}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "invites" do
    field :name, :string
    field :token, :string
    field :uses_left, :integer, default: nil
    field :disabled_at, :naive_datetime

    belongs_to :user, User

    timestamps()
  end

  @type t :: %Invite{
          id: UUID.t(),
          name: String.t(),
          token: String.t(),
          uses_left: integer() | nil,
          disabled_at: NaiveDateTime.t(),
          user: User.t(),
          user_id: UUID.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @type new_invite :: %Invite{}

  @doc false
  @spec changeset(Invite.t() | Invite.new_invite(), map()) :: Changeset.t()
  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:name, :token, :uses_left, :disabled_at, :user_id])
    |> validate_required([:name, :token, :user_id])
    |> validate_number(:uses_left, greater_than_or_equal_to: 0)
  end
end
