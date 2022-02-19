defmodule CanneryWeb.Components.ContainerCard do
  @moduledoc """
  Display card for a container
  """

  use CanneryWeb, :component
  import CanneryWeb.Components.TagCard
  alias Cannery.{Repo, Containers}
  alias CanneryWeb.Endpoint

  def container_card(%{container: container} = assigns) do
    assigns = assigns |> Map.put(:container, container |> Repo.preload([:tags, :ammo_groups]))

    ~H"""
    <div
      id={"container-#{@container.id}"}
      class="mx-4 my-2 px-8 py-4 flex flex-col justify-center items-center space-y-4
        border border-gray-400 rounded-lg shadow-lg hover:shadow-md
        transition-all duration-300 ease-in-out"
    >
      <div class="mb-4 flex flex-col justify-center items-center space-y-2">
        <%= live_redirect to: Routes.container_show_path(Endpoint, :show, @container),
                      class: "link" do %>
          <h1 class="px-4 py-2 rounded-lg title text-xl">
            <%= @container.name %>
          </h1>
        <% end %>

        <%= if @container.desc do %>
          <span class="rounded-lg title text-lg">
            <%= gettext("Description:") %>
            <%= @container.desc %>
          </span>
        <% end %>

        <span class="rounded-lg title text-lg">
          <%= gettext("Type:") %>
          <%= @container.type %>
        </span>

        <%= if @container.location do %>
          <span class="rounded-lg title text-lg">
            <%= gettext("Location:") %>
            <%= @container.location %>
          </span>
        <% end %>

        <%= if @container.ammo_groups do %>
          <span class="rounded-lg title text-lg">
            <%= gettext("Rounds:") %>
            <%= @container |> Containers.get_container_rounds!() %>
          </span>
        <% end %>

        <div class="flex flex-wrap justify-center items-center">
          <%= unless @container.tags |> Enum.empty?() do %>
            <%= for tag <- @container.tags do %>
              <.simple_tag_card tag={tag} />
            <% end %>
          <% end %>

          <%= if assigns |> Map.has_key?(:tag_actions) do %>
            <%= render_slot(@tag_actions) %>
          <% end %>
        </div>
      </div>

      <%= if assigns |> Map.has_key?(:inner_block) do %>
        <div class="flex space-x-4 justify-center items-center">
          <%= render_slot(@inner_block) %>
        </div>
      <% end %>
    </div>
    """
  end
end
