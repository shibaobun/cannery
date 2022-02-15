defmodule CanneryWeb.Components.ContainerCard do
  @moduledoc """
  Display card for a container
  """

  use CanneryWeb, :component
  alias CanneryWeb.Endpoint

  def container_card(assigns) do
    ~H"""
    <div
      id={"container-#{@container.id}"}
      class="mx-4 my-2 px-8 py-4 flex flex-col justify-center items-center
        border border-gray-400 rounded-lg shadow-lg hover:shadow-md"
    >
      <div class="mb-4 flex flex-col justify-center items-center">
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
