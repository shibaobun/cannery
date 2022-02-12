defmodule CanneryWeb.Components.UserCard do
  @moduledoc """
  Display card for a user
  """

  use CanneryWeb, :component

  def user_card(assigns) do
    ~H"""
    <div
      id={"user-#{@user.id}"}
      class="mx-4 my-2 px-8 py-4 flex flex-col justify-center items-center
          border border-gray-400 rounded-lg shadow-lg hover:shadow-md"
    >
      <h1 class="px-4 py-2 rounded-lg title text-xl">
        <%= @user.email %>
      </h1>

      <h3 class="px-4 py-2 rounded-lg title text-lg">
        <%= if @user.confirmed_at |> is_nil() do %>
          Email unconfirmed
        <% else %>
          User was confirmed at <%= @user.confirmed_at |> display_datetime() %>
        <% end %>
      </h3>

      <%= if @inner_block do %>
        <div class="px-4 py-2 flex space-x-4 justify-center items-center">
          <%= render_slot(@inner_block) %>
        </div>
      <% end %>
    </div>
    """
  end
end
