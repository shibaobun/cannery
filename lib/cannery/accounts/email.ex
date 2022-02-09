defmodule Cannery.Email do
  @moduledoc """
  Emails that can be sent using Swoosh.

  You can find the base email templates at
  `lib/cannery_web/templates/layout/email.html.heex` for html emails and
  `lib/cannery_web/templates/layout/email.txt.heex` for text emails.
  """

  use Phoenix.Swoosh, view: Cannery.EmailView, layout: {Cannery.LayoutView, :email}
  import CanneryWeb.Gettext
  alias Cannery.Accounts.User
  alias CanneryWeb.EmailView

  @typedoc """
  Represents an HTML and text body email that can be sent
  """
  @type t() :: Swoosh.Email.t()

  @spec base_email(User.t(), String.t()) :: t()
  defp base_email(%User{email: email}, subject) do
    new()
    |> to(email)
    |> from({
      Application.get_env(:cannery, Cannery.Mailer)[:email_name],
      Application.get_env(:cannery, Cannery.Mailer)[:email_from]
    })
    |> subject(subject)
  end

  @spec welcome_email(User.t(), String.t()) :: t()
  def welcome_email(user, url) do
    user
    |> base_email(dgettext("emails", "Confirm your %{name} account", name: "Cannery"))
    |> render_body("confirm_email.html", %{user: user, url: url})
    |> text_body(EmailView.render("confirm_email.txt", %{user: user, url: url}))
  end

  @spec reset_password_email(User.t(), String.t()) :: t()
  def reset_password_email(user, url) do
    user
    |> base_email(dgettext("emails", "Reset your %{name} password", name: "Cannery"))
    |> render_body("reset_password.html", %{user: user, url: url})
    |> text_body(EmailView.render("reset_password.txt", %{user: user, url: url}))
  end

  @spec update_email(User.t(), String.t()) :: t()
  def update_email(user, url) do
    user
    |> base_email(dgettext("emails", "Update your %{name} email", name: "Cannery"))
    |> render_body("update_email.html", %{user: user, url: url})
    |> text_body(EmailView.render("update_email.txt", %{user: user, url: url}))
  end
end
