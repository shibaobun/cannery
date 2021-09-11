defmodule CanneryWeb.Live.Component.Topbar do
  use CanneryWeb, :live_component

  alias Cannery.{Accounts}

  def mount(socket) do
    {:ok, socket |> assign(results: [], title_content: nil)}
  end

  def update(assigns, socket) do
    {:ok, socket |> assign(assigns)}
  end
end
