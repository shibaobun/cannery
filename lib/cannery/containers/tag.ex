defmodule Cannery.Containers.Tag do
  @moduledoc """
  Tags are added to containers to help organize, and can include custom-defined
  text and bg colors.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Cannery.Accounts.User
  alias Ecto.{Changeset, UUID}

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

    field :user_id, :binary_id

    timestamps()
  end

  @type t :: %__MODULE__{
          id: id(),
          name: String.t(),
          bg_color: String.t(),
          text_color: String.t(),
          user_id: User.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_tag() :: %__MODULE__{}
  @type id() :: UUID.t()
  @type changeset() :: Changeset.t(t() | new_tag())

  @doc false
  @spec create_changeset(new_tag(), User.t(), attrs :: map()) :: changeset()
  def create_changeset(tag, %User{id: user_id}, attrs) do
    tag
    |> change(user_id: user_id)
    |> cast(attrs, [:name, :bg_color, :text_color])
    |> validate_length(:name, max: 255)
    |> validate_length(:bg_color, max: 12)
    |> validate_length(:text_color, max: 12)
    |> validate_required([:name, :bg_color, :text_color, :user_id])
  end

  @doc false
  @spec update_changeset(t() | new_tag(), attrs :: map()) :: changeset()
  def update_changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :bg_color, :text_color])
    |> validate_length(:name, max: 255)
    |> validate_length(:bg_color, max: 12)
    |> validate_length(:text_color, max: 12)
    |> validate_required([:name, :bg_color, :text_color])
  end
end
