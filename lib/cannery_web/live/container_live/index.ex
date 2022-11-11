defmodule CanneryWeb.ContainerLive.Index do
  @moduledoc """
  Liveview for showing Cannery.Containers.Container index
  """

  use CanneryWeb, :live_view
  import CanneryWeb.Components.ContainerCard
  alias Cannery.{Containers, Containers.Container, Repo}
  alias CanneryWeb.{Components.TagCard, Endpoint}
  alias Ecto.Changeset

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket |> assign(view_table: false)}

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params) |> display_containers()}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    %{name: container_name} =
      container =
      Containers.get_container!(id, current_user)
      |> Repo.preload([:tags, :ammo_groups], force: true)

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
      container: nil
    )
    |> display_containers()
  end

  defp apply_action(socket, :table, _params) do
    socket
    |> assign(
      page_title: gettext("Containers"),
      container: nil,
      view_table: true
    )
    |> display_containers()
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit_tags, %{"id" => id}) do
    %{name: container_name} =
      container =
      Containers.get_container!(id, current_user) |> Repo.preload([:tags, :ammo_groups])

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

            {:error, %{action: :delete, errors: [ammo_groups: _error], valid?: false} = changeset} ->
              ammo_groups_error = changeset |> changeset_errors(:ammo_groups) |> Enum.join(", ")

              prompt =
                dgettext(
                  "errors",
                  "Could not delete %{name}: %{error}",
                  name: changeset |> Changeset.get_field(:name, "container"),
                  error: ammo_groups_error
                )

              socket |> put_flash(:error, prompt)

            {:error, changeset} ->
              socket |> put_flash(:error, changeset |> changeset_errors())
          end
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_table", _params, %{assigns: %{view_table: view_table}} = socket) do
    new_path =
      if view_table,
        do: Routes.container_index_path(Endpoint, :index),
        else: Routes.container_index_path(Endpoint, :table)

    {:noreply, socket |> assign(view_table: !view_table) |> push_patch(to: new_path)}
  end

  defp display_containers(%{assigns: %{current_user: current_user}} = socket) do
    containers =
      Containers.list_containers(current_user) |> Repo.preload([:tags, :ammo_groups], force: true)

    columns =
      [
        %{label: gettext("Name"), key: :name, type: :string},
        %{label: gettext("Description"), key: :desc, type: :string},
        %{label: gettext("Location"), key: :location, type: :string},
        %{label: gettext("Type"), key: :type, type: :string},
        %{label: gettext("Packs"), key: :packs, type: :integer},
        %{label: gettext("Rounds"), key: :rounds, type: :string},
        %{label: gettext("Tags"), key: :tags, type: :tags},
        %{label: nil, key: :actions, sortable: false, type: :actions}
      ]
      |> Enum.filter(fn %{key: key, type: type} ->
        # remove columns if all values match defaults
        default_value =
          case type do
            :boolean -> false
            _other_type -> nil
          end

        containers
        |> Enum.any?(fn container ->
          type in [:tags, :actions] or not (container |> Map.get(key) == default_value)
        end)
      end)

    rows =
      containers
      |> Enum.map(fn container -> container |> get_row_data_for_container(columns) end)

    socket
    |> assign(
      containers: containers,
      columns: columns,
      rows: rows
    )
  end

  @spec get_row_data_for_container(Container.t(), [map()]) :: [map()]
  defp get_row_data_for_container(container, columns) do
    container = container |> Repo.preload([:ammo_groups, :tags])

    columns
    |> Enum.into(%{}, fn %{key: key} -> {key, get_value_for_key(key, container)} end)
  end

  @spec get_value_for_key(atom(), Container.t()) :: any()
  defp get_value_for_key(:packs, container) do
    container |> Containers.get_container_ammo_group_count!()
  end

  defp get_value_for_key(:rounds, container) do
    container |> Containers.get_container_rounds!()
  end

  defp get_value_for_key(:tags, container) do
    assigns = %{container: container}

    {container.tags |> Enum.map(fn %{name: name} -> name end),
     ~H"""
     <div class="flex flex-wrap justify-center items-center">
       <%= unless @container.tags |> Enum.empty?() do %>
         <%= for tag <- @container.tags do %>
           <TagCard.simple_tag_card tag={tag} />
         <% end %>
       <% end %>

       <div class="mx-4 my-2">
         <.link
           patch={Routes.container_index_path(Endpoint, :edit_tags, @container)}
           class="text-primary-600 link"
         >
           <i class="fa-fw fa-lg fas fa-tags"></i>
         </.link>
       </div>
     </div>
     """}
  end

  defp get_value_for_key(:actions, container) do
    assigns = %{container: container}

    ~H"""
    <.link
      patch={Routes.container_index_path(Endpoint, :edit, @container)}
      class="text-primary-600 link"
      data-qa={"edit-#{@container.id}"}
    >
      <i class="fa-fw fa-lg fas fa-edit"></i>
    </.link>

    <.link
      patch={Routes.container_index_path(Endpoint, :clone, @container)}
      class="text-primary-600 link"
      data-qa={"clone-#{@container.id}"}
    >
      <i class="fa-fw fa-lg fas fa-copy"></i>
    </.link>

    <.link
      href="#"
      class="text-primary-600 link"
      phx-click="delete"
      phx-value-id={@container.id}
      data-confirm={
        dgettext("prompts", "Are you sure you want to delete %{name}?", name: @container.name)
      }
      data-qa={"delete-#{@container.id}"}
    >
      <i class="fa-fw fa-lg fas fa-trash"></i>
    </.link>
    """
  end

  defp get_value_for_key(key, container), do: container |> Map.get(key)

  def return_to(true = _view_table), do: Routes.container_index_path(Endpoint, :table)
  def return_to(false = _view_table), do: Routes.container_index_path(Endpoint, :index)
end
