defmodule CanneryWeb.UserRegistrationController do
  use CanneryWeb, :controller
  import CanneryWeb.Gettext
  alias Cannery.{Accounts, Accounts.Invites}
  alias Ecto.Changeset

  def new(conn, %{"invite" => invite_token}) do
    if Invites.valid_invite_token?(invite_token) do
      conn |> render_new(invite_token)
    else
      conn
      |> put_flash(:error, dgettext("errors", "Sorry, this invite was not found or expired"))
      |> redirect(to: ~p"/")
    end
  end

  def new(conn, _params) do
    if Accounts.allow_registration?() do
      conn |> render_new()
    else
      conn
      |> put_flash(:error, dgettext("errors", "Sorry, public registration is disabled"))
      |> redirect(to: ~p"/")
    end
  end

  # renders new user registration page
  defp render_new(conn, invite_token \\ nil) do
    render(conn, :new,
      changeset: Accounts.change_user_registration(),
      invite_token: invite_token,
      page_title: gettext("Register")
    )
  end

  def create(conn, %{"user" => %{"invite_token" => invite_token}} = attrs) do
    if Invites.valid_invite_token?(invite_token) do
      conn |> create_user(attrs, invite_token)
    else
      conn
      |> put_flash(:error, dgettext("errors", "Sorry, this invite was not found or expired"))
      |> redirect(to: ~p"/")
    end
  end

  def create(conn, attrs) do
    if Accounts.allow_registration?() do
      conn |> create_user(attrs)
    else
      conn
      |> put_flash(:error, dgettext("errors", "Sorry, public registration is disabled"))
      |> redirect(to: ~p"/")
    end
  end

  defp create_user(conn, %{"user" => user_params}, invite_token \\ nil) do
    case Accounts.register_user(user_params, invite_token) do
      {:ok, user} ->
        Accounts.deliver_user_confirmation_instructions(
          user,
          fn token -> url(CanneryWeb.Endpoint, ~p"/users/confirm/#{token}") end
        )

        conn
        |> put_flash(:info, dgettext("prompts", "Please check your email to verify your account"))
        |> redirect(to: ~p"/users/log_in")

      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, dgettext("errors", "Sorry, this invite was not found or expired"))
        |> redirect(to: ~p"/")

      {:error, %Changeset{} = changeset} ->
        conn |> render("new.html", changeset: changeset, invite_token: invite_token)
    end
  end
end
