defmodule CanneryWeb.Components.AmmoGroupCard do
  @moduledoc """
  Display card for an ammo group
  """

  use CanneryWeb, :component
  alias Cannery.{Ammo, Ammo.AmmoGroup, Repo}
  alias CanneryWeb.Endpoint

  attr :ammo_group, AmmoGroup, required: true
  attr :show_container, :boolean, default: false
  slot(:inner_block)

  def ammo_group_card(%{ammo_group: ammo_group} = assigns) do
    assigns =
      %{show_container: show_container} = assigns |> assign_new(:show_container, fn -> false end)

    preloads = if show_container, do: [:ammo_type, :container], else: [:ammo_type]
    ammo_group = ammo_group |> Repo.preload(preloads)

    assigns = assigns |> assign(:ammo_group, ammo_group)

    ~H"""
    <div
      id={"ammo_group-#{@ammo_group.id}"}
      class="mx-4 my-2 px-8 py-4 flex flex-col justify-center items-center
            border border-gray-400 rounded-lg shadow-lg hover:shadow-md
            transition-all duration-300 ease-in-out"
    >
      <.link navigate={Routes.ammo_group_show_path(Endpoint, :show, @ammo_group)} class="mb-2 link">
        <h1 class="title text-xl title-primary-500">
          <%= @ammo_group.ammo_type.name %>
        </h1>
      </.link>

      <div class="flex flex-col justify-center items-center">
        <span class="rounded-lg title text-lg">
          <%= gettext("Count:") %>
          <%= if @ammo_group.count == 0, do: gettext("Empty"), else: @ammo_group.count %>
        </span>

        <%= if @ammo_group |> Ammo.get_original_count() != @ammo_group.count do %>
          <span class="rounded-lg title text-lg">
            <%= gettext("Original Count:") %>
            <%= @ammo_group |> Ammo.get_original_count() %>
          </span>
        <% end %>

        <%= if @ammo_group.notes do %>
          <span class="rounded-lg title text-lg">
            <%= gettext("Notes:") %>
            <%= @ammo_group.notes %>
          </span>
        <% end %>

        <span class="rounded-lg title text-lg">
          <%= gettext("Purchased on:") %>
          <%= @ammo_group.purchased_on |> display_date() %>
        </span>

        <%= if @ammo_group |> Ammo.get_last_used_shot_group() do %>
          <span class="rounded-lg title text-lg">
            <%= gettext("Last used on:") %>
            <%= @ammo_group |> Ammo.get_last_used_shot_group() |> Map.get(:date) |> display_date() %>
          </span>
        <% end %>

        <%= if @ammo_group.price_paid do %>
          <span class="rounded-lg title text-lg">
            <%= gettext("Price paid:") %>
            <%= gettext("$%{amount}",
              amount: @ammo_group.price_paid |> :erlang.float_to_binary(decimals: 2)
            ) %>
          </span>

          <span class="rounded-lg title text-lg">
            <%= gettext("CPR:") %>
            <%= gettext("$%{amount}",
              amount: @ammo_group |> Ammo.get_cpr() |> :erlang.float_to_binary(decimals: 2)
            ) %>
          </span>
        <% end %>

        <%= if @show_container and @ammo_group.container do %>
          <span class="rounded-lg title text-lg">
            <%= gettext("Container:") %>

            <.link
              navigate={Routes.container_show_path(Endpoint, :show, @ammo_group.container)}
              class="link"
            >
              <%= @ammo_group.container.name %>
            </.link>
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
