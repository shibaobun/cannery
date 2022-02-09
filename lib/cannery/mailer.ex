defmodule Cannery.Mailer do
  @moduledoc """
  Mailer adapter for emails
  """

  use Swoosh.Mailer, otp_app: :cannery
  alias Cannery.{Accounts.User, Email, EmailWorker}
  alias Oban.Job

  @doc """
  Deliver instructions to confirm account.
  """
  @spec deliver_confirmation_instructions(User.t(), String.t()) :: {:ok, Job.t()}
  def deliver_confirmation_instructions(user, url) do
    {:ok, Email.welcome_email(user, url) |> EmailWorker.new() |> Oban.insert!()}
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  @spec deliver_reset_password_instructions(User.t(), String.t()) :: {:ok, Job.t()}
  def deliver_reset_password_instructions(user, url) do
    {:ok, Email.reset_password_email(user, url) |> EmailWorker.new() |> Oban.insert!()}
  end

  @doc """
  Deliver instructions to update a user email.
  """
  @spec deliver_update_email_instructions(User.t(), String.t()) :: {:ok, Job.t()}
  def deliver_update_email_instructions(user, url) do
    {:ok, Email.update_email(user, url) |> EmailWorker.new() |> Oban.insert!()}
  end
end
