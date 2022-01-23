defmodule Cannery.Mailer do
  @moduledoc """
  Mailer adapter for emails
  """

  use Swoosh.Mailer, otp_app: :cannery
end
