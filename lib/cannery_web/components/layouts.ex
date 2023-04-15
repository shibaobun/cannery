defmodule CanneryWeb.Layouts do
  @moduledoc """
  The root layouts for the entire application
  """

  use CanneryWeb, :html

  embed_templates "layouts/*"

  def get_title(%{assigns: %{title: title}}) when title not in [nil, ""] do
    gettext("Cannery | %{title}", title: title)
  end

  def get_title(_conn) do
    gettext("Cannery")
  end
end
