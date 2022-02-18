defmodule CanneryWeb.Components.AmmoGroupCard do
  @moduledoc """
  Display card for an ammo group
  """

  use CanneryWeb, :component
  alias Cannery.Repo
  alias CanneryWeb.Endpoint

  def ammo_group_card(assigns) do
    assigns = assigns |> assign(:ammo_group, assigns.ammo_group |> Repo.preload(:ammo_type))

    ~H"""
    <div
      id={"ammo_group-#{@ammo_group.id}"}
      class="mx-4 my-2 px-8 py-4 flex flex-col justify-center items-center
            border border-gray-400 rounded-lg shadow-lg hover:shadow-md
            transition-all duration-300 ease-in-out"
    >
      <%= live_redirect to: Routes.ammo_group_show_path(Endpoint, :show, @ammo_group),
                    class: "mb-2 link" do %>
        <h1 class="title text-xl title-primary-500">
          <%= @ammo_group.ammo_type.name %>
        </h1>
      <% end %>

      <div class="flex flex-col justify-center items-center">
        <span class="rounded-lg title text-lg">
          <%= gettext("Count:") %>
          <%= @ammo_group.count %>
        </span>

        <%= if @ammo_group.notes do %>
          <span class="rounded-lg title text-lg">
            <%= gettext("Notes:") %>
            <%= @ammo_group.notes %>
          </span>
        <% end %>

        <%= if @ammo_group.price_paid do %>
          <span class="rounded-lg title text-lg">
            <%= gettext("Price paid:") %>
            <%= gettext("$%{amount}",
              amount: @ammo_group.price_paid |> :erlang.float_to_binary(decimals: 2)
            ) %>
          </span>
        <% end %>
      </div>

      <%= if assigns |> Map.has_key?(:inner_block) do %>
        <div class="mt-4 flex space-x-4 justify-center items-center">
          <%= render_slot(@inner_block) %>
        </div>
      <% end %>
    </div>
    """
  end
end
