defmodule Cannery.Fixtures do
  @moduledoc """
  This module defines test helpers for creating entities
  """

  alias Cannery.{
    Accounts,
    Accounts.User,
    ActivityLog.ShotGroup,
    Ammo,
    Ammo.AmmoGroup,
    Ammo.AmmoType,
    Containers,
    Containers.Container,
    Containers.Tag,
    Email,
    Repo
  }

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  @spec user_fixture() :: User.t()
  @spec user_fixture(attrs :: map()) :: User.t()
  def user_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      "email" => unique_user_email(),
      "password" => valid_user_password()
    })
    |> Accounts.register_user()
    |> unwrap_ok_tuple()
  end

  @spec admin_fixture() :: User.t()
  @spec admin_fixture(attrs :: map()) :: User.t()
  def admin_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      "email" => unique_user_email(),
      "password" => valid_user_password()
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
  @spec shot_group_fixture(User.t(), AmmoGroup.t()) :: ShotGroup.t()
  @spec shot_group_fixture(attrs :: map(), User.t(), AmmoGroup.t()) :: ShotGroup.t()
  def shot_group_fixture(attrs \\ %{}, %User{} = user, %AmmoGroup{} = ammo_group) do
    attrs
    |> Enum.into(%{
      "count" => 20,
      "date" => ~N[2022-02-13 03:17:00],
      "notes" => "some notes"
    })
    |> Cannery.ActivityLog.create_shot_group(user, ammo_group)
    |> unwrap_ok_tuple()
  end

  @doc """
  Generate a Container
  """
  @spec container_fixture(User.t()) :: Container.t()
  @spec container_fixture(attrs :: map(), User.t()) :: Container.t()
  def container_fixture(attrs \\ %{}, %User{} = user) do
    attrs
    |> Enum.into(%{"name" => "My container", "type" => "Ammo can"})
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
    |> Enum.into(%{"name" => "ammo_type"})
    |> Ammo.create_ammo_type(user)
    |> unwrap_ok_tuple()
  end

  @doc """
  Generate a AmmoGroup
  """
  @spec ammo_group_fixture(AmmoType.t(), Container.t(), User.t()) ::
          {count :: non_neg_integer(), [AmmoGroup.t()]}
  @spec ammo_group_fixture(attrs :: map(), AmmoType.t(), Container.t(), User.t()) ::
          {count :: non_neg_integer(), [AmmoGroup.t()]}
  @spec ammo_group_fixture(
          attrs :: map(),
          multiplier :: non_neg_integer(),
          AmmoType.t(),
          Container.t(),
          User.t()
        ) :: {count :: non_neg_integer(), [AmmoGroup.t()]}
  def ammo_group_fixture(
        attrs \\ %{},
        multiplier \\ 1,
        %AmmoType{id: ammo_type_id},
        %Container{id: container_id},
        %User{} = user
      ) do
    attrs
    |> Enum.into(%{
      "ammo_type_id" => ammo_type_id,
      "container_id" => container_id,
      "count" => 20,
      "purchased_on" => Date.utc_today()
    })
    |> Ammo.create_ammo_groups(multiplier, user)
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
      "bg_color" => "some bg-color",
      "name" => "some name",
      "text_color" => "some text-color"
    })
    |> Containers.create_tag(user)
    |> unwrap_ok_tuple()
  end

  defp unwrap_ok_tuple({:ok, value}), do: value
end
