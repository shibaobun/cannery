defmodule CanneryWeb.Components.ContainerCard do
  @moduledoc """
  Display card for a container
  """

  use CanneryWeb, :component
  import CanneryWeb.Components.TagCard
  alias Cannery.{Containers, Containers.Container, Repo}
  alias CanneryWeb.Endpoint
  alias Phoenix.LiveView.Rendered

  attr :container, Container, required: true
  slot(:tag_actions)
  slot(:inner_block)

  @spec container_card(assigns :: map()) :: Rendered.t()
  def container_card(%{container: container} = assigns) do
    assigns =
      assigns
      |> assign(container: container |> Repo.preload([:tags, :ammo_groups]))
      |> assign_new(:tag_actions, fn -> [] end)

    ~H"""
    <div
      id={"container-#{@container.id}"}
      class="overflow-hidden max-w-full mx-4 mb-4 px-8 py-4 flex flex-col justify-center items-center space-y-4
        border border-gray-400 rounded-lg shadow-lg hover:shadow-md
        transition-all duration-300 ease-in-out"
    >
      <div class="max-w-full mb-4 flex flex-col justify-center items-center space-y-2">
        <.link navigate={Routes.container_show_path(Endpoint, :show, @container)} class="link">
          <h1 class="px-4 py-2 rounded-lg title text-xl">
            <%= @container.name %>
          </h1>
        </.link>

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

        <%= unless @container.ammo_groups |> Enum.empty?() do %>
          <span class="rounded-lg title text-lg">
            <%= gettext("Packs:") %>
            <%= @container |> Containers.get_container_ammo_group_count!() %>
          </span>

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

          <%= render_slot(@tag_actions) %>
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
