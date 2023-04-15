defmodule CanneryWeb.EmailController do
  @moduledoc """
  A dev controller used to develop on emails
  """

  use CanneryWeb, :controller
  alias Cannery.Accounts.User

  plug :put_root_layout, html: {CanneryWeb.Layouts, :email_html}
  plug :put_layout, false

  @sample_assigns %{
    email: %{subject: "Example subject"},
    url: "https://cannery.bubbletea.dev/sample_url",
    user: %User{email: "sample@email.com"}
  }

  @doc """
  Debug route used to preview emails
  """
  def preview(conn, %{"id" => template}) do
    render(conn, String.to_existing_atom(template), @sample_assigns)
  end
end
