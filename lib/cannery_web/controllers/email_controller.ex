defmodule CanneryWeb.EmailController do
  @moduledoc """
  A dev controller used to develop on emails
  """

  use CanneryWeb, :controller
  alias Cannery.Accounts.User

  plug :put_layout, {CanneryWeb.LayoutView, :email}

  @sample_assigns %{
    email: %{subject: "Example subject"},
    url: "https://cannery.bubbletea.dev/sample_url",
    user: %User{email: "sample@email.com"}
  }

  @doc """
  Debug route used to preview emails
  """
  def preview(conn, %{"id" => template}) do
    render(conn, "#{template |> to_string()}.html", @sample_assigns)
  end
end
