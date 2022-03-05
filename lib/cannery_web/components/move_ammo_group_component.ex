defmodule CanneryWeb.Components.MoveAmmoGroupComponent do
  @moduledoc """
  Livecomponent that can move an ammo group to another container
  """

  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Ammo, Ammo.AmmoGroup, Containers, Containers.Container}
  alias CanneryWeb.Endpoint
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(
          %{
            required(:current_user) => User.t(),
            required(:ammo_group) => AmmoGroup.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(
        %{ammo_group: %{container_id: container_id} = ammo_group, current_user: current_user} =
          assigns,
        socket
      ) do
    changeset = Ammo.change_ammo_group(ammo_group)

    containers =
      Containers.list_containers(current_user)
      |> Enum.reject(fn %{id: id} -> id == container_id end)

    socket =
      socket
      |> assign(assigns)
      |> assign(changeset: changeset, containers: containers)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "move",
        %{"container_id" => container_id},
        %{assigns: %{ammo_group: ammo_group, current_user: current_user, return_to: return_to}} =
          socket
      ) do
    %{name: container_name} = Containers.get_container!(container_id, current_user)

    socket =
      ammo_group
      |> Ammo.update_ammo_group(%{"container_id" => container_id}, current_user)
      |> case do
        {:ok, _ammo_group} ->
          prompt = dgettext("prompts", "Ammo moved to %{name} successfully", name: container_name)

          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Ecto.Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def render(%{containers: containers} = assigns) do
    columns = [
      %{label: gettext("Container"), key: "name"},
      %{label: gettext("Type"), key: "type"},
      %{label: gettext("Location"), key: "location"},
      %{
        label: nil,
        key: "actions",
        sortable: false,
        class: "px-4 py-2 space-x-4 flex justify-center items-center"
      }
    ]

    rows = containers |> get_rows_for_containers(assigns, columns)

    assigns = assigns |> Map.merge(%{columns: columns, rows: rows})

    ~H"""
    <div class="w-full flex flex-col space-y-8 justify-center items-center">
      <h2 class="mb-8 text-center title text-xl text-primary-600">
        <%= gettext("Move ammo") %>
      </h2>

      <%= if @containers |> Enum.empty?() do %>
        <h2 class="title text-xl text-primary-600">
          <%= gettext("No other containers") %>
          <%= display_emoji("😔") %>
        </h2>

        <%= live_patch(dgettext("actions", "Add another container!"),
          to: Routes.container_index_path(Endpoint, :new),
          class: "btn btn-primary"
        ) %>
      <% else %>
        <.live_component
          module={CanneryWeb.Components.TableComponent}
          id="move_ammo_group_table"
          columns={@columns}
          rows={@rows}
        />
      <% end %>
    </div>
    """
  end

  @spec get_rows_for_containers([Container.t()], map(), [map()]) :: [map()]
  defp get_rows_for_containers(containers, assigns, columns) do
    containers
    |> Enum.map(fn container ->
      assigns = assigns |> Map.put(:container, container)

      columns
      |> Enum.into(%{}, fn %{key: key} ->
        value =
          case key do
            "actions" ->
              ~H"""
              <button
                type="button"
                class="btn btn-primary"
                phx-click="move"
                phx-target={@myself}
                phx-value-container_id={container.id}
              >
                <%= dgettext("actions", "Select") %>
              </button>
              """

            key ->
              container |> Map.get(key |> String.to_existing_atom())
          end

        {key, value}
      end)
    end)
  end
end
