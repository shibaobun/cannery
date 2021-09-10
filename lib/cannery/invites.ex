defmodule Cannery.Invites do
  @moduledoc """
  The Invites context.
  """

  import Ecto.Query, warn: false
  alias Cannery.{Accounts, Repo}
  alias Cannery.Invites.Invite

  @invite_token_length 20

  @doc """
  Returns the list of invites.

  ## Examples

      iex> list_invites()
      [%Invite{}, ...]

  """
  def list_invites, do: Repo.all(Invite)

  @doc """
  Gets a single invite.

  Raises `Ecto.NoResultsError` if the Invite does not exist.

  ## Examples

      iex> get_invite!(123)
      %Invite{}

      iex> get_invite!(456)
      ** (Ecto.NoResultsError)

  """
  def get_invite!(id), do: Repo.get!(Invite, id)

  @doc """
  Returns a valid invite or nil based on the attempted token

  ## Examples

      iex> get_invite_by_token("valid_token")
      %Invite{}

      iex> get_invite_by_token("invalid_token")
      nil
  """
  @spec get_invite_by_token(String.t()) :: Invite.t() | nil
  def get_invite_by_token(nil), do: nil
  def get_invite_by_token(""), do: nil
  def get_invite_by_token(token), do: Repo.get_by(Invite, token: token, disabled_at: nil)

  @doc """
  Uses invite by decrementing uses_left, or markes invite invalid if it's been completely used

  """
  @spec use_invite!(Invite.t()) :: Invite.t()
  def use_invite!(%Invite{uses_left: uses_left} = invite) do
    new_uses_left = uses_left - 1

    attrs =
      if new_uses_left <= 0 do
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        %{"uses_left" => 0, "disabled_at" => now}
      else
        %{"uses_left" => new_uses_left}
      end

    invite |> Invite.changeset(attrs) |> Repo.update!()
  end

  @doc """
  Creates a invite.

  ## Examples

      iex> create_invite(%Accounts.User{id: "1"}, %{field: value})
      {:ok, %Invite{}}

      iex> create_invite("1", %{field: value})
      {:ok, %Invite{}}

      iex> create_invite(%Accounts.User{id: "1"}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_invite(Accounts.User.t() | Ecto.UUID.t(), map()) :: Invite.t()
  def create_invite(%Accounts.User{id: user_id}, attrs) do
    create_invite(user_id, attrs)
  end

  def create_invite(user_id, attrs) when not (user_id |> is_nil()) do
    attrs =
      attrs
      |> Map.merge(%{
        "user_id" => user_id,
        "token" => :crypto.strong_rand_bytes(@invite_token_length)
      })

    %Invite{} |> Invite.changeset(attrs) |> Repo.insert()
  end

  @doc """
  Updates a invite.

  ## Examples

      iex> update_invite(invite, %{field: new_value})
      {:ok, %Invite{}}

      iex> update_invite(invite, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_invite(%Invite{} = invite, attrs) do
    invite
    |> Invite.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a invite.

  ## Examples

      iex> delete_invite(invite)
      {:ok, %Invite{}}

      iex> delete_invite(invite)
      {:error, %Ecto.Changeset{}}

  """
  def delete_invite(%Invite{} = invite) do
    Repo.delete(invite)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invite changes.

  ## Examples

      iex> change_invite(invite)
      %Ecto.Changeset{data: %Invite{}}

  """
  def change_invite(%Invite{} = invite, attrs \\ %{}) do
    Invite.changeset(invite, attrs)
  end
end
