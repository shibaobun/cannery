defmodule CanneryWeb.UserResetPasswordController do
  use CanneryWeb, :controller

  alias Cannery.Accounts

  plug :get_user_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, :new, page_title: gettext("Forgot your password?"))
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        fn token -> url(CanneryWeb.Endpoint, ~p"/users/reset_password/#{token}") end
      )
    end

    # Regardless of the outcome, show an impartial success/error message.
    conn
    |> put_flash(
      :info,
      dgettext(
        "prompts",
        "If your email is in our system, you will receive instructions to reset your password shortly."
      )
    )
    |> redirect(to: ~p"/")
  end

  def edit(conn, _params) do
    render(conn, :edit,
      changeset: Accounts.change_user_password(conn.assigns.user),
      page_title: gettext("Reset your password")
    )
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def update(conn, %{"user" => user_params}) do
    case Accounts.reset_user_password(conn.assigns.user, user_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, dgettext("prompts", "Password reset successfully."))
        |> redirect(to: ~p"/users/log_in")

      {:error, changeset} ->
        render(conn, :edit, changeset: changeset)
    end
  end

  defp get_user_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if user = Accounts.get_user_by_reset_password_token(token) do
      conn |> assign(:user, user) |> assign(:token, token)
    else
      conn
      |> put_flash(
        :error,
        dgettext("errors", "Reset password link is invalid or it has expired.")
      )
      |> redirect(to: ~p"/")
      |> halt()
    end
  end
end
