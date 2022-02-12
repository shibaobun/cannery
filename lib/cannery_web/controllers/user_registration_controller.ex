defmodule CanneryWeb.UserRegistrationController do
  use CanneryWeb, :controller
  import CanneryWeb.Gettext
  alias Cannery.{Accounts, Invites}
  alias Cannery.Accounts.User
  alias CanneryWeb.{Endpoint, HomeLive}

  def new(conn, %{"invite" => invite_token}) do
    invite = Invites.get_invite_by_token(invite_token)

    if invite do
      conn |> render_new(invite)
    else
      conn
      |> put_flash(:error, dgettext("errors", "Sorry, this invite was not found or expired"))
      |> redirect(to: Routes.live_path(Endpoint, HomeLive))
    end
  end

  def new(conn, _params) do
    if Accounts.allow_registration?() do
      conn |> render_new()
    else
      conn
      |> put_flash(:error, dgettext("errors", "Sorry, public registration is disabled"))
      |> redirect(to: Routes.live_path(Endpoint, HomeLive))
    end
  end

  # renders new user registration page
  defp render_new(conn, invite \\ nil) do
    changeset = Accounts.change_user_registration(%User{})
    conn |> render("new.html", changeset: changeset, invite: invite)
  end

  def create(conn, %{"user" => %{"invite_token" => invite_token}} = attrs) do
    invite = Invites.get_invite_by_token(invite_token)

    if invite do
      conn |> create_user(attrs, invite)
    else
      conn
      |> put_flash(:error, dgettext("errors", "Sorry, this invite was not found or expired"))
      |> redirect(to: Routes.live_path(Endpoint, HomeLive))
    end
  end

  def create(conn, attrs) do
    if Accounts.allow_registration?() do
      conn |> create_user(attrs)
    else
      conn
      |> put_flash(:error, dgettext("errors", "Sorry, public registration is disabled"))
      |> redirect(to: Routes.live_path(Endpoint, HomeLive))
    end
  end

  defp create_user(conn, %{"user" => user_params}, invite \\ nil) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        unless invite |> is_nil() do
          invite |> Invites.use_invite!()
        end

        Accounts.deliver_user_confirmation_instructions(
          user,
          &Routes.user_confirmation_url(conn, :confirm, &1)
        )

        conn
        |> put_flash(:info, dgettext("prompts", "Please check your email to verify your account"))
        |> redirect(to: Routes.user_session_path(Endpoint, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, invite: invite)
    end
  end
end
