defmodule LokalWeb.Components.InviteCard do
  @moduledoc """
  Display card for an invite
  """

  use LokalWeb, :component
  alias Lokal.Accounts.{Invite, Invites, User}
  alias LokalWeb.Endpoint

  attr :invite, Invite, required: true
  attr :current_user, User, required: true
  slot(:inner_block)
  slot(:code_actions)

  def invite_card(%{invite: invite, current_user: current_user} = assigns) do
    assigns =
      assigns
      |> assign(:use_count, Invites.get_use_count(invite, current_user))
      |> assign_new(:code_actions, fn -> [] end)

    ~H"""
    <div class="mx-4 my-2 px-8 py-4 flex flex-col justify-center items-center space-y-4
      border border-gray-400 rounded-lg shadow-lg hover:shadow-md
      transition-all duration-300 ease-in-out">
      <h1 class="title text-xl">
        <%= @invite.name %>
      </h1>

      <%= if @invite.disabled_at |> is_nil() do %>
        <h2 class="title text-md">
          <%= if @invite.uses_left do %>
            <%= gettext(
              "Uses Left: %{uses_left_count}",
              uses_left_count: @invite.uses_left
            ) %>
          <% else %>
            <%= gettext("Uses Left: Unlimited") %>
          <% end %>
        </h2>
      <% else %>
        <h2 class="title text-md">
          <%= gettext("Invite Disabled") %>
        </h2>
      <% end %>

      <.qr_code
        content={Routes.user_registration_url(Endpoint, :new, invite: @invite.token)}
        filename={@invite.name}
      />

      <h2 :if={@use_count != 0} class="title text-md">
        <%= gettext("Uses: %{uses_count}", uses_count: @use_count) %>
      </h2>

      <div class="flex flex-row flex-wrap justify-center items-center">
        <code
          id={"code-#{@invite.id}"}
          class="mx-2 my-1 text-xs px-4 py-2 rounded-lg text-center break-all text-gray-100 bg-primary-800"
          phx-no-format
        ><%= Routes.user_registration_url(Endpoint, :new, invite: @invite.token) %></code>
        <%= render_slot(@code_actions) %>
      </div>

      <div :if={@inner_block} class="flex space-x-4 justify-center items-center">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
