defmodule CanneryWeb.Components.InviteCard do
  @moduledoc """
  Display card for an invite
  """

  use CanneryWeb, :component
  alias Cannery.Invites.Invite
  alias CanneryWeb.Endpoint

  attr :invite, Invite, required: true
  slot(:inner_block)
  slot(:code_actions)

  def invite_card(assigns) do
    assigns = assigns |> assign_new(:code_actions, fn -> [] end)

    ~H"""
    <div class="mx-4 my-2 px-8 py-4 flex flex-col justify-center items-center space-y-4
      border border-gray-400 rounded-lg shadow-lg hover:shadow-md
      transition-all duration-300 ease-in-out">
      <h1 class="title text-xl">
        <%= @invite.name %>
      </h1>

      <%= if @invite.disabled_at |> is_nil() do %>
        <h2 class="title text-md">
          <%= gettext("Uses Left:") %>
          <%= @invite.uses_left || "Unlimited" %>
        </h2>
      <% else %>
        <h2 class="title text-md">
          <%= gettext("Invite Disabled") %>
        </h2>
      <% end %>

      <div class="flex flex-row flex-wrap justify-center items-center">
        <code
          id={"code-#{@invite.id}"}
          class="mx-2 my-1 text-xs px-4 py-2 rounded-lg text-center break-all text-gray-100 bg-primary-800"
        >
          <%= Routes.user_registration_url(Endpoint, :new, invite: @invite.token) %>
        </code>

        <%= render_slot(@code_actions) %>
      </div>

      <%= if @inner_block do %>
        <div class="flex space-x-4 justify-center items-center">
          <%= render_slot(@inner_block) %>
        </div>
      <% end %>
    </div>
    """
  end
end
