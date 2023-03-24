defmodule CanneryWeb.ContainerLive.Show do
  @moduledoc """
  Liveview for showing and editing a Cannery.Containers.Container
  """

  use CanneryWeb, :live_view
  alias Cannery.{Accounts.User, ActivityLog, Ammo, Containers, Containers.Container}
  alias CanneryWeb.Endpoint
  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(_params, _session, socket),
    do: {:ok, socket |> assign(type: :all, view_table: true)}

  @impl true
  def handle_params(%{"id" => id}, _session, %{assigns: %{current_user: current_user}} = socket) do
    socket =
      socket
      |> assign(view_table: true)
      |> render_container(id, current_user)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "delete_tag",
        %{"tag-id" => tag_id},
        %{assigns: %{container: container, current_user: current_user}} = socket
      ) do
    socket =
      case Containers.get_tag(tag_id, current_user) do
        {:ok, tag} ->
          _count = Containers.remove_tag!(container, tag, current_user)

          prompt =
            dgettext("prompts", "%{tag_name} has been removed from %{container_name}",
              tag_name: tag.name,
              container_name: container.name
            )

          socket |> put_flash(:info, prompt) |> render_container()

        {:error, :not_found} ->
          socket |> put_flash(:error, dgettext("errors", "Tag not found"))
      end

    {:noreply, socket}
  end

  def handle_event(
        "delete_container",
        _params,
        %{assigns: %{container: container, current_user: current_user}} = socket
      ) do
    socket =
      Containers.delete_container(container, current_user)
      |> case do
        {:ok, %{name: container_name}} ->
          prompt = dgettext("prompts", "%{name} has been deleted", name: container_name)

          socket
          |> put_flash(:info, prompt)
          |> push_navigate(to: Routes.container_index_path(socket, :index))

        {:error, %{action: :delete, errors: [ammo_groups: _error], valid?: false} = changeset} ->
          ammo_groups_error = changeset |> changeset_errors(:ammo_groups) |> Enum.join(", ")

          prompt =
            dgettext("errors", "Could not delete %{name}: %{error}",
              name: changeset |> Changeset.get_field(:name, "container"),
              error: ammo_groups_error
            )

          socket |> put_flash(:error, prompt)

        {:error, changeset} ->
          socket |> put_flash(:error, changeset |> changeset_errors())
      end

    {:noreply, socket}
  end

  def handle_event("toggle_table", _params, %{assigns: %{view_table: view_table}} = socket) do
    {:noreply, socket |> assign(:view_table, !view_table) |> render_container()}
  end

  def handle_event("change_type", %{"ammo_type" => %{"type" => "rifle"}}, socket) do
    {:noreply, socket |> assign(:type, :rifle) |> render_container()}
  end

  def handle_event("change_type", %{"ammo_type" => %{"type" => "shotgun"}}, socket) do
    {:noreply, socket |> assign(:type, :shotgun) |> render_container()}
  end

  def handle_event("change_type", %{"ammo_type" => %{"type" => "pistol"}}, socket) do
    {:noreply, socket |> assign(:type, :pistol) |> render_container()}
  end

  def handle_event("change_type", %{"ammo_type" => %{"type" => _all}}, socket) do
    {:noreply, socket |> assign(:type, :all) |> render_container()}
  end

  @spec render_container(Socket.t(), Container.id(), User.t()) :: Socket.t()
  defp render_container(
         %{assigns: %{type: type, live_action: live_action}} = socket,
         id,
         current_user
       ) do
    %{name: container_name} = container = Containers.get_container!(id, current_user)
    ammo_groups = Ammo.list_ammo_groups_for_container(container, type, current_user)
    original_counts = ammo_groups |> Ammo.get_original_counts(current_user)
    cprs = ammo_groups |> Ammo.get_cprs(current_user)
    last_used_dates = ammo_groups |> ActivityLog.get_last_used_dates(current_user)

    page_title =
      case live_action do
        :show -> container_name
        :edit -> gettext("Edit %{name}", name: container_name)
        :edit_tags -> gettext("Edit %{name} tags", name: container_name)
      end

    socket
    |> assign(
      container: container,
      round_count: Ammo.get_round_count_for_container!(container, current_user),
      ammo_groups_count: Ammo.get_ammo_groups_count_for_container!(container, current_user),
      ammo_groups: ammo_groups,
      original_counts: original_counts,
      cprs: cprs,
      last_used_dates: last_used_dates,
      page_title: page_title
    )
  end

  @spec render_container(Socket.t()) :: Socket.t()
  defp render_container(
         %{assigns: %{container: %{id: container_id}, current_user: current_user}} = socket
       ) do
    socket |> render_container(container_id, current_user)
  end
end
