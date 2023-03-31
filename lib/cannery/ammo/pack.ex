defmodule Cannery.Ammo.Pack do
  @moduledoc """
  A group of a certain ammunition type.

  Can be placed in a container, and contains auxiliary information such as the
  amount paid for that ammunition, or what condition it is in
  """

  use Ecto.Schema
  import CanneryWeb.Gettext
  import Ecto.Changeset
  alias Cannery.Ammo.Type
  alias Cannery.{Accounts.User, Containers, Containers.Container}
  alias Ecto.{Changeset, UUID}

  @derive {Jason.Encoder,
           only: [
             :id,
             :count,
             :notes,
             :price_paid,
             :staged,
             :type_id,
             :container_id
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "packs" do
    field :count, :integer
    field :notes, :string
    field :price_paid, :float
    field :staged, :boolean, default: false
    field :purchased_on, :date

    belongs_to :type, Type
    field :container_id, :binary_id
    field :user_id, :binary_id

    timestamps()
  end

  @type t :: %__MODULE__{
          id: id(),
          count: integer,
          notes: String.t() | nil,
          price_paid: float() | nil,
          staged: boolean(),
          purchased_on: Date.t(),
          type: Type.t() | nil,
          type_id: Type.id(),
          container_id: Container.id(),
          user_id: User.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_pack :: %__MODULE__{}
  @type id :: UUID.t()
  @type changeset :: Changeset.t(t() | new_pack())

  @doc false
  @spec create_changeset(
          new_pack(),
          Type.t() | nil,
          Container.t() | nil,
          User.t(),
          attrs :: map()
        ) :: changeset()
  def create_changeset(
        pack,
        %Type{id: type_id},
        %Container{id: container_id, user_id: user_id},
        %User{id: user_id},
        attrs
      )
      when is_binary(type_id) and is_binary(container_id) and is_binary(user_id) do
    pack
    |> change(type_id: type_id)
    |> change(user_id: user_id)
    |> change(container_id: container_id)
    |> cast(attrs, [:count, :price_paid, :notes, :staged, :purchased_on])
    |> validate_number(:count, greater_than: 0)
    |> validate_required([:count, :staged, :purchased_on, :type_id, :container_id, :user_id])
  end

  @doc """
  Invalid changeset, used to prompt user to select type and container
  """
  def create_changeset(pack, _invalid_type, _invalid_container, _invalid_user, attrs) do
    pack
    |> cast(attrs, [:type_id, :container_id])
    |> validate_required([:type_id, :container_id])
    |> add_error(:invalid, dgettext("errors", "Please select a type and container"))
  end

  @doc false
  @spec update_changeset(t() | new_pack(), attrs :: map(), User.t()) :: changeset()
  def update_changeset(pack, attrs, user) do
    pack
    |> cast(attrs, [:count, :price_paid, :notes, :staged, :purchased_on, :container_id])
    |> validate_number(:count, greater_than_or_equal_to: 0)
    |> validate_container_id(user)
    |> validate_required([:count, :staged, :purchased_on, :container_id])
  end

  defp validate_container_id(changeset, user) do
    container_id = changeset |> Changeset.get_field(:container_id)

    if container_id do
      Containers.get_container!(container_id, user)
    end

    changeset
  end

  @doc """
  This range changeset is used when "using up" packs, and allows for
  updating the count to 0
  """
  @spec range_changeset(t() | new_pack(), attrs :: map()) :: changeset()
  def range_changeset(pack, attrs) do
    pack
    |> cast(attrs, [:count, :staged])
    |> validate_required([:count, :staged])
  end
end
