defmodule Cannery.Ammo.AmmoGroup do
  @moduledoc """
  A group of a certain ammunition type.

  Can be placed in a container, and contains auxiliary information such as the
  amount paid for that ammunition, or what condition it is in
  """

  use Ecto.Schema
  import CanneryWeb.Gettext
  import Ecto.Changeset
  alias Cannery.Ammo.AmmoType
  alias Cannery.{Accounts.User, Containers, Containers.Container}
  alias Ecto.{Changeset, UUID}

  @derive {Jason.Encoder,
           only: [
             :id,
             :count,
             :notes,
             :price_paid,
             :staged,
             :ammo_type_id,
             :container_id
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ammo_groups" do
    field :count, :integer
    field :notes, :string
    field :price_paid, :float
    field :staged, :boolean, default: false
    field :purchased_on, :date

    belongs_to :ammo_type, AmmoType
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
          ammo_type: AmmoType.t() | nil,
          ammo_type_id: AmmoType.id(),
          container_id: Container.id(),
          user_id: User.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_ammo_group :: %__MODULE__{}
  @type id :: UUID.t()
  @type changeset :: Changeset.t(t() | new_ammo_group())

  @doc false
  @spec create_changeset(
          new_ammo_group(),
          AmmoType.t() | nil,
          Container.t() | nil,
          User.t(),
          attrs :: map()
        ) :: changeset()
  def create_changeset(
        ammo_group,
        %AmmoType{id: ammo_type_id},
        %Container{id: container_id, user_id: user_id},
        %User{id: user_id},
        attrs
      )
      when is_binary(ammo_type_id) and is_binary(container_id) and is_binary(user_id) do
    ammo_group
    |> change(ammo_type_id: ammo_type_id)
    |> change(user_id: user_id)
    |> change(container_id: container_id)
    |> cast(attrs, [:count, :price_paid, :notes, :staged, :purchased_on])
    |> validate_number(:count, greater_than: 0)
    |> validate_required([:count, :staged, :purchased_on, :ammo_type_id, :container_id, :user_id])
  end

  @doc """
  Invalid changeset, used to prompt user to select ammo type and container
  """
  def create_changeset(ammo_group, _invalid_ammo_type, _invalid_container, _invalid_user, attrs) do
    ammo_group
    |> cast(attrs, [:ammo_type_id, :container_id])
    |> validate_required([:ammo_type_id, :container_id])
    |> add_error(:invalid, dgettext("errors", "Please select an ammo type and container"))
  end

  @doc false
  @spec update_changeset(t() | new_ammo_group(), attrs :: map(), User.t()) :: changeset()
  def update_changeset(ammo_group, attrs, user) do
    ammo_group
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
  This range changeset is used when "using up" ammo groups, and allows for
  updating the count to 0
  """
  @spec range_changeset(t() | new_ammo_group(), attrs :: map()) :: changeset()
  def range_changeset(ammo_group, attrs) do
    ammo_group
    |> cast(attrs, [:count, :staged])
    |> validate_required([:count, :staged])
  end
end
