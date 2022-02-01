defmodule Cannery.Tags.Tag do
  @moduledoc """
  Tags are added to containers to help organize, and can include custom-defined
  text and bg colors.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.{Changeset, UUID}
  alias Cannery.{Accounts.User, Tags.Tag}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tags" do
    field :name, :string
    field :bg_color, :string
    field :text_color, :string

    belongs_to :user, User

    timestamps()
  end

  @type t :: %Tag{
          id: id(),
          name: String.t(),
          bg_color: String.t(),
          text_color: String.t(),
          user: User.t(),
          user_id: User.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_tag() :: %Tag{}
  @type id() :: UUID.t()

  @doc false
  @spec changeset(t() | new_tag(), attrs :: map()) :: Changeset.t()
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :bg_color, :text_color, :user_id])
    |> validate_required([:name, :bg_color, :text_color, :user_id])
  end
end
