defmodule CanneryWeb.Components.ContainerTableComponent do
  @moduledoc """
  A component that displays a list of containers
  """
  use CanneryWeb, :live_component
  alias Cannery.{Accounts.User, Containers, Containers.Container, Repo}
  alias CanneryWeb.Components.TagCard
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

    extra_data = %{
      current_user: current_user,
      tag_actions: tag_actions,
      actions: actions
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
    container = container |> Repo.preload([:ammo_groups, :tags])

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

  defp get_value_for_key(:packs, container, _extra_data) do
    container |> Containers.get_container_ammo_group_count!()
  end

  defp get_value_for_key(:rounds, container, _extra_data) do
    container |> Containers.get_container_rounds!()
  end

  defp get_value_for_key(:tags, container, %{tag_actions: tag_actions}) do
    assigns = %{tag_actions: tag_actions, container: container}

    {container.tags |> Enum.map(fn %{name: name} -> name end),
     ~H"""
     <div class="flex flex-wrap justify-center items-center">
       <%= unless @container.tags |> Enum.empty?() do %>
         <%= for tag <- @container.tags do %>
           <TagCard.simple_tag_card tag={tag} />
         <% end %>
       <% end %>

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
