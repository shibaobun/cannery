defmodule Cannery.Tags.Tag do
  @moduledoc """
  Tags are added to containers to help organize, and can include custom-defined
  text and bg colors.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.{Changeset, UUID}
  alias Cannery.{Accounts.User, Tags.Tag}

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :bg_color,
             :text_color
           ]}
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
          user: User.t() | nil,
          user_id: User.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_tag() :: %Tag{}
  @type id() :: UUID.t()
  @type changeset() :: Changeset.t(t() | new_tag())

  @doc false
  @spec create_changeset(new_tag(), User.t(), attrs :: map()) :: changeset()
  def create_changeset(tag, %User{id: user_id}, attrs) do
    tag
    |> change(user_id: user_id)
    |> cast(attrs, [:name, :bg_color, :text_color])
    |> validate_required([:name, :bg_color, :text_color, :user_id])
  end

  @doc false
  @spec update_changeset(t() | new_tag(), attrs :: map()) :: changeset()
  def update_changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :bg_color, :text_color])
    |> validate_required([:name, :bg_color, :text_color])
  end
end
