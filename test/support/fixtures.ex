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
    Containers.Container
  }

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  @spec user_fixture() :: Accounts.User.t()
  @spec user_fixture(attrs :: map()) :: Accounts.User.t()
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        "email" => unique_user_email(),
        "password" => valid_user_password()
      })
      |> Accounts.register_user()

    user
  end

  @spec admin_fixture() :: Accounts.User.t()
  @spec admin_fixture(attrs :: map()) :: Accounts.User.t()
  def admin_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        "email" => unique_user_email(),
        "password" => valid_user_password(),
        "role" => "admin"
      })
      |> Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
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
    {:ok, shot_group} =
      attrs
      |> Enum.into(%{
        "count" => 25,
        "date" => ~N[2022-02-13 03:17:00],
        "notes" => "some notes"
      })
      |> Cannery.ActivityLog.create_shot_group(user, ammo_group)

    shot_group
  end

  @doc """
  Generate a Container
  """
  @spec container_fixture(User.t()) :: Container.t()
  @spec container_fixture(attrs :: map(), User.t()) :: Container.t()
  def container_fixture(attrs \\ %{}, %User{} = user) do
    {:ok, container} =
      attrs
      |> Enum.into(%{"name" => "My container", "type" => "Ammo can"})
      |> Containers.create_container(user)

    container
  end

  @doc """
  Generate a AmmoType
  """
  @spec ammo_type_fixture(User.t()) :: AmmoType.t()
  @spec ammo_type_fixture(attrs :: map(), User.t()) :: AmmoType.t()
  def ammo_type_fixture(attrs \\ %{}, %User{} = user) do
    {:ok, ammo_type} =
      attrs
      |> Enum.into(%{"name" => "ammo_type"})
      |> Ammo.create_ammo_type(user)

    ammo_type
  end

  @doc """
  Generate a AmmoGroup
  """
  @spec ammo_group_fixture(AmmoType.t(), Container.t(), User.t()) :: AmmoGroup.t()
  @spec ammo_group_fixture(attrs :: map(), AmmoType.t(), Container.t(), User.t()) :: AmmoGroup.t()
  def ammo_group_fixture(
        attrs \\ %{},
        %AmmoType{id: ammo_type_id},
        %Container{id: container_id},
        %User{} = user
      ) do
    {:ok, ammo_group} =
      attrs
      |> Enum.into(%{
        "ammo_type_id" => ammo_type_id,
        "container_id" => container_id,
        "count" => 20
      })
      |> Ammo.create_ammo_group(user)

    ammo_group
  end
end
