defmodule Cannery.Fixtures do
  @moduledoc """
  This module defines test helpers for creating entities
  """

  import Cannery.DataCase

  alias Cannery.{
    Accounts,
    Accounts.User,
    ActivityLog.ShotGroup,
    Ammo,
    Ammo.AmmoType,
    Ammo.Pack,
    Containers,
    Containers.Container,
    Containers.Tag,
    Email,
    Repo
  }

  @spec user_fixture() :: User.t()
  @spec user_fixture(attrs :: map()) :: User.t()
  def user_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      email: unique_user_email(),
      password: valid_user_password()
    })
    |> Accounts.register_user()
    |> unwrap_ok_tuple()
  end

  @spec admin_fixture() :: User.t()
  @spec admin_fixture(attrs :: map()) :: User.t()
  def admin_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      email: unique_user_email(),
      password: valid_user_password()
    })
    |> Accounts.register_user()
    |> unwrap_ok_tuple()
    |> User.role_changeset(:admin)
    |> Repo.update!()
  end

  def extract_user_token(fun) do
    %{args: %{attrs: attrs, email: email_key, user_id: user_id}} = fun.(&"[TOKEN]#{&1}[TOKEN]")

    # convert atoms to string keys
    attrs = attrs |> Map.new(fn {atom_key, value} -> {atom_key |> Atom.to_string(), value} end)

    email =
      email_key
      |> Atom.to_string()
      |> Email.generate_email(Accounts.get_user!(user_id), attrs)

    [_, html_token | _] = email.html_body |> String.split("[TOKEN]")
    [_, text_token | _] = email.text_body |> String.split("[TOKEN]")
    ^text_token = html_token
  end

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  @doc """
  Generate a ShotGroup
  """
  @spec shot_group_fixture(User.t(), Pack.t()) :: ShotGroup.t()
  @spec shot_group_fixture(attrs :: map(), User.t(), Pack.t()) :: ShotGroup.t()
  def shot_group_fixture(attrs \\ %{}, %User{} = user, %Pack{} = pack) do
    attrs
    |> Enum.into(%{
      count: 20,
      date: ~N[2022-02-13 03:17:00],
      notes: random_string()
    })
    |> Cannery.ActivityLog.create_shot_group(user, pack)
    |> unwrap_ok_tuple()
  end

  @doc """
  Generate a Container
  """
  @spec container_fixture(User.t()) :: Container.t()
  @spec container_fixture(attrs :: map(), User.t()) :: Container.t()
  def container_fixture(attrs \\ %{}, %User{} = user) do
    attrs
    |> Enum.into(%{
      name: random_string(),
      type: "Ammo can",
      location: random_string(),
      desc: random_string()
    })
    |> Containers.create_container(user)
    |> unwrap_ok_tuple()
  end

  @doc """
  Generate a AmmoType
  """
  @spec ammo_type_fixture(User.t()) :: AmmoType.t()
  @spec ammo_type_fixture(attrs :: map(), User.t()) :: AmmoType.t()
  def ammo_type_fixture(attrs \\ %{}, %User{} = user) do
    attrs
    |> Enum.into(%{
      name: random_string(),
      class: :rifle,
      desc: random_string(),
      bullet_type: random_string(),
      bullet_core: random_string(),
      cartridge: random_string(),
      caliber: random_string(),
      case_material: random_string(),
      jacket_type: random_string(),
      muzzle_velocity: 3,
      powder_type: random_string(),
      powder_grains_per_charge: 5,
      grains: 7,
      pressure: random_string(),
      primer_type: random_string(),
      firing_type: random_string(),
      wadding: random_string(),
      shot_type: random_string(),
      shot_material: random_string(),
      shot_size: random_string(),
      unfired_length: random_string(),
      brass_height: random_string(),
      chamber_size: random_string(),
      load_grains: 9,
      shot_charge_weight: random_string(),
      dram_equivalent: random_string(),
      tracer: false,
      incendiary: false,
      blank: false,
      corrosive: false,
      manufacturer: random_string(),
      upc: random_string()
    })
    |> Ammo.create_ammo_type(user)
    |> unwrap_ok_tuple()
  end

  @doc """
  Generate a Pack
  """
  @spec pack_fixture(AmmoType.t(), Container.t(), User.t()) ::
          {count :: non_neg_integer(), [Pack.t()]}
  @spec pack_fixture(attrs :: map(), AmmoType.t(), Container.t(), User.t()) ::
          {count :: non_neg_integer(), [Pack.t()]}
  @spec pack_fixture(
          attrs :: map(),
          multiplier :: non_neg_integer(),
          AmmoType.t(),
          Container.t(),
          User.t()
        ) :: {count :: non_neg_integer(), [Pack.t()]}
  def pack_fixture(
        attrs \\ %{},
        multiplier \\ 1,
        %AmmoType{id: ammo_type_id},
        %Container{id: container_id},
        %User{} = user
      ) do
    attrs
    |> Enum.into(%{
      ammo_type_id: ammo_type_id,
      container_id: container_id,
      count: 20,
      purchased_on: Date.utc_today()
    })
    |> Ammo.create_packs(multiplier, user)
    |> unwrap_ok_tuple()
  end

  @doc """
  Generates a Tag
  """
  @spec tag_fixture(User.t()) :: Tag.t()
  @spec tag_fixture(attrs :: map(), User.t()) :: Tag.t()
  def tag_fixture(attrs \\ %{}, %User{} = user) do
    attrs
    |> Enum.into(%{
      bg_color: "#100000",
      name: random_string(),
      text_color: "#000000"
    })
    |> Containers.create_tag(user)
    |> unwrap_ok_tuple()
  end

  defp unwrap_ok_tuple({:ok, value}), do: value
end
