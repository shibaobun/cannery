defmodule CanneryWeb.Component.Topbar do
  @moduledoc """
  Component that renders a topbar with user functions/links
  """

  use CanneryWeb, :component

  alias Cannery.Accounts
  alias CanneryWeb.HomeLive

  def topbar(assigns) do
    assigns =
      %{results: [], title_content: nil, flash: nil, current_user: nil} |> Map.merge(assigns)

    ~H"""
    <header class="mb-8 px-8 py-4 w-full bg-primary-400">
      <nav role="navigation">
        <div class="flex flex-row justify-between items-center space-x-4">
          <div class="flex flex-row justify-start items-center space-x-2">
            <%= link to: Routes.live_path(CanneryWeb.Endpoint, HomeLive) do %>
              <h1 class="leading-5 text-xl text-white hover:underline">
                Cannery
              </h1>
            <% end %>
            <%= if @title_content do %>
              <span>|</span>
              <%= @title_content %>
            <% end %>
          </div>
          <ul class="flex flex-row flex-wrap justify-center items-center
            space-x-4 text-lg text-white">
            <%= if @current_user do %>
              <li>
                <%= link("Tags",
                  class: "hover:underline",
                  to: Routes.tag_index_path(CanneryWeb.Endpoint, :index)
                ) %>
              </li>
              <li>
                <%= link("Containers",
                  class: "hover:underline",
                  to: Routes.container_index_path(CanneryWeb.Endpoint, :index)
                ) %>
              </li>
              <li>
                <%= link("Ammo",
                  class: "hover:underline",
                  to: Routes.ammo_type_index_path(CanneryWeb.Endpoint, :index)
                ) %>
              </li>
              <li>
                <%= link("Manage",
                  class: "hover:underline",
                  to: Routes.ammo_group_index_path(CanneryWeb.Endpoint, :index)
                ) %>
              </li>
              <%= if @current_user.role == :admin do %>
                <li>
                  <%= link("Invites",
                    class: "hover:underline",
                    to: Routes.invite_index_path(CanneryWeb.Endpoint, :index)
                  ) %>
                </li>
              <% end %>
              <li>
                <%= link(@current_user.email,
                  class: "hover:underline",
                  to: Routes.user_settings_path(CanneryWeb.Endpoint, :edit)
                ) %>
              </li>
              <li>
                <%= link to: Routes.user_session_path(CanneryWeb.Endpoint, :delete),
                     method: :delete,
                     data: [confirm: "Are you sure you want to log out?"] do %>
                  <i class="fas fa-sign-out-alt">
                  </i>
                <% end %>
              </li>
              <%= if @current_user.role == :admin and function_exported?(Routes, :live_dashboard_path, 2) do %>
                <li>
                  <%= link to: Routes.live_dashboard_path(CanneryWeb.Endpoint, :home) do %>
                    <i class="fas fa-tachometer-alt">
                    </i>
                  <% end %>
                </li>
              <% end %>
            <% else %>
              <%= if Accounts.allow_registration?() do %>
                <li>
                  <%= link("Register",
                    class: "hover:underline",
                    to: Routes.user_registration_path(CanneryWeb.Endpoint, :new)
                  ) %>
                </li>
              <% end %>
              <li>
                <%= link("Log in",
                  class: "hover:underline",
                  to: Routes.user_session_path(CanneryWeb.Endpoint, :new)
                ) %>
              </li>
            <% end %>
          </ul>
        </div>
      </nav>
      <%= if @flash && @flash |> Map.has_key?(:info) do %>
        <p class="alert alert-info" role="alert" phx-click="lv:clear-flash" phx-value-key="info">
          <%= live_flash(@flash, :info) %>
        </p>
      <% end %>
      <%= if @flash && @flash |> Map.has_key?(:error) do %>
        <p class="alert alert-danger" role="alert" phx-click="lv:clear-flash" phx-value-key="error">
          <%= live_flash(@flash, :error) %>
        </p>
      <% end %>
    </header>
    """
  end
end
