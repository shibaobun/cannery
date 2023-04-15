defmodule CanneryWeb.ContainerLive.Index do
  @moduledoc """
  Liveview for showing Cannery.Containers.Container index
  """

  use CanneryWeb, :live_view
  alias Cannery.{Containers, Containers.Container}
  alias Ecto.Changeset

  @impl true
  def mount(%{"search" => search}, _session, socket) do
    {:ok, socket |> assign(view_table: true, search: search) |> display_containers()}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(view_table: true, search: nil) |> display_containers()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params) |> display_containers()}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    %{name: container_name} = container = Containers.get_container!(id, current_user)

    socket
    |> assign(page_title: gettext("Edit %{name}", name: container_name), container: container)
  end

  defp apply_action(socket, :new, _params) do
    socket |> assign(:page_title, gettext("New Container")) |> assign(:container, %Container{})
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :clone, %{"id" => id}) do
    container = Containers.get_container!(id, current_user)

    socket
    |> assign(page_title: gettext("New Container"), container: %{container | id: nil})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      page_title: gettext("Containers"),
      container: nil,
      search: nil
    )
  end

  defp apply_action(socket, :search, %{"search" => search}) do
    socket
    |> assign(
      page_title: gettext("Containers"),
      container: nil,
      search: search
    )
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit_tags, %{"id" => id}) do
    %{name: container_name} = container = Containers.get_container!(id, current_user)

    page_title = gettext("Edit %{name} tags", name: container_name)
    socket |> assign(page_title: page_title, container: container)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    socket =
      socket.assigns.containers
      |> Enum.find(fn %{id: container_id} -> id == container_id end)
      |> case do
        nil ->
          socket |> put_flash(:error, dgettext("errors", "Could not find that container"))

        container ->
          case Containers.delete_container(container, current_user) do
            {:ok, %{name: container_name}} ->
              prompt = dgettext("prompts", "%{name} has been deleted", name: container_name)
              socket |> put_flash(:info, prompt) |> display_containers()

            {:error, %{action: :delete, errors: [packs: _error], valid?: false} = changeset} ->
              packs_error = changeset |> changeset_errors(:packs) |> Enum.join(", ")

              prompt =
                dgettext(
                  "errors",
                  "Could not delete %{name}: %{error}",
                  name: changeset |> Changeset.get_field(:name, "container"),
                  error: packs_error
                )

              socket |> put_flash(:error, prompt)

            {:error, changeset} ->
              socket |> put_flash(:error, changeset |> changeset_errors())
          end
      end

    {:noreply, socket}
  end

  def handle_event("toggle_table", _params, %{assigns: %{view_table: view_table}} = socket) do
    {:noreply, socket |> assign(:view_table, !view_table) |> display_containers()}
  end

  def handle_event("search", %{"search" => %{"search_term" => ""}}, socket) do
    {:noreply, socket |> push_patch(to: ~p"/containers")}
  end

  def handle_event("search", %{"search" => %{"search_term" => search_term}}, socket) do
    {:noreply, socket |> push_patch(to: ~p"/containers/search/#{search_term}")}
  end

  defp display_containers(%{assigns: %{search: search, current_user: current_user}} = socket) do
    socket |> assign(:containers, Containers.list_containers(search, current_user))
  end
end
