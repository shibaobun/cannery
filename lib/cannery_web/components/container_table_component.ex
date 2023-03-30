defmodule CanneryWeb.Components.ContainerTableComponent do
  @moduledoc """
  A component that displays a list of containers
  """
  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Ammo, Containers.Container}
  alias Ecto.UUID
  alias Phoenix.LiveView.{Rendered, Socket}

  @impl true
  @spec update(
          %{
            required(:id) => UUID.t(),
            required(:current_user) => User.t(),
            optional(:containers) => [Container.t()],
            optional(:tag_actions) => Rendered.t(),
            optional(:actions) => Rendered.t(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{id: _id, containers: _containers, current_user: _current_user} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:tag_actions, fn -> [] end)
      |> assign_new(:actions, fn -> [] end)
      |> display_containers()

    {:ok, socket}
  end

  defp display_containers(
         %{
           assigns: %{
             containers: containers,
             current_user: current_user,
             tag_actions: tag_actions,
             actions: actions
           }
         } = socket
       ) do
    columns =
      [
        %{label: gettext("Name"), key: :name, type: :string},
        %{label: gettext("Description"), key: :desc, type: :string},
        %{label: gettext("Location"), key: :location, type: :string},
        %{label: gettext("Type"), key: :type, type: :string}
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
      |> Enum.concat([
        %{label: gettext("Packs"), key: :packs, type: :integer},
        %{label: gettext("Rounds"), key: :rounds, type: :integer},
        %{label: gettext("Tags"), key: :tags, type: :tags},
        %{label: gettext("Actions"), key: :actions, sortable: false, type: :actions}
      ])

    extra_data = %{
      current_user: current_user,
      tag_actions: tag_actions,
      actions: actions,
      pack_count: Ammo.get_packs_count_for_containers(containers, current_user),
      round_count: Ammo.get_round_count_for_containers(containers, current_user)
    }

    rows =
      containers
      |> Enum.map(fn container ->
        container |> get_row_data_for_container(columns, extra_data)
      end)

    socket
    |> assign(
      columns: columns,
      rows: rows
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="w-full">
      <.live_component
        module={CanneryWeb.Components.TableComponent}
        id={"table-#{@id}"}
        columns={@columns}
        rows={@rows}
      />
    </div>
    """
  end

  @spec get_row_data_for_container(Container.t(), columns :: [map()], extra_data :: map) :: map()
  defp get_row_data_for_container(container, columns, extra_data) do
    columns
    |> Map.new(fn %{key: key} -> {key, get_value_for_key(key, container, extra_data)} end)
  end

  @spec get_value_for_key(atom(), Container.t(), extra_data :: map) :: any()
  defp get_value_for_key(:name, %{id: id, name: container_name}, _extra_data) do
    assigns = %{id: id, container_name: container_name}

    {container_name,
     ~H"""
     <div class="flex flex-wrap justify-center items-center">
       <.link navigate={Routes.container_show_path(Endpoint, :show, @id)} class="link">
         <%= @container_name %>
       </.link>
     </div>
     """}
  end

  defp get_value_for_key(:packs, %{id: container_id}, %{pack_count: pack_count}) do
    pack_count |> Map.get(container_id, 0)
  end

  defp get_value_for_key(:rounds, %{id: container_id}, %{round_count: round_count}) do
    round_count |> Map.get(container_id, 0)
  end

  defp get_value_for_key(:tags, container, %{tag_actions: tag_actions}) do
    assigns = %{tag_actions: tag_actions, container: container}

    tag_names =
      container.tags
      |> Enum.map(fn %{name: name} -> name end)
      |> Enum.sort()
      |> Enum.join(" ")

    {tag_names,
     ~H"""
     <div class="flex flex-wrap justify-center items-center">
       <.simple_tag_card :for={tag <- @container.tags} :if={@container.tags} tag={tag} />

       <%= render_slot(@tag_actions, @container) %>
     </div>
     """}
  end

  defp get_value_for_key(:actions, container, %{actions: actions}) do
    assigns = %{actions: actions, container: container}

    ~H"""
    <%= render_slot(@actions, @container) %>
    """
  end

  defp get_value_for_key(key, container, _extra_data), do: container |> Map.get(key)
end
