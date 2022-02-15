defmodule CanneryWeb.Components.Topbar do
  @moduledoc """
  Component that renders a topbar with user functions/links
  """

  use CanneryWeb, :component

  alias Cannery.Accounts
  alias CanneryWeb.{Endpoint, HomeLive}

  def topbar(assigns) do
    assigns =
      %{results: [], title_content: nil, flash: nil, current_user: nil} |> Map.merge(assigns)

    ~H"""
    <header class="mb-8 px-8 py-4 w-full bg-primary-400 overflow-x-hidden">
      <nav role="navigation">
        <div class="flex flex-row justify-between items-center space-x-4">
          <div class="flex flex-row justify-start items-center space-x-2">
            <%= link to: Routes.live_path(Endpoint, HomeLive) do %>
              <h1 class="leading-5 text-xl text-white hover:underline">
                Cannery
              </h1>
            <% end %>
            <%= if @title_content do %>
              <span>|</span>
              <%= @title_content %>
            <% end %>
          </div>

          <ul class="flex flex-col sm:flex-row flex-wrap justify-center items-center
            space-x-4 text-lg text-white text-ellipsis">
            <%= if @current_user do %>
              <li>
                <%= link(gettext("Tags"),
                  class: "hover:underline",
                  to: Routes.tag_index_path(Endpoint, :index)
                ) %>
              </li>
              <li>
                <%= link(gettext("Containers"),
                  class: "hover:underline",
                  to: Routes.container_index_path(Endpoint, :index)
                ) %>
              </li>
              <li>
                <%= link(gettext("Ammo"),
                  class: "hover:underline",
                  to: Routes.ammo_type_index_path(Endpoint, :index)
                ) %>
              </li>
              <li>
                <%= link(gettext("Manage"),
                  class: "hover:underline",
                  to: Routes.ammo_group_index_path(Endpoint, :index)
                ) %>
              </li>
              <li>
                <%= link(gettext("Range"),
                  class: "hover:underline",
                  to: Routes.range_index_path(Endpoint, :index)
                ) %>
              </li>
              <%= if @current_user.role == :admin do %>
                <li>
                  <%= link(gettext("Invites"),
                    class: "hover:underline",
                    to: Routes.invite_index_path(Endpoint, :index)
                  ) %>
                </li>
              <% end %>
              <li>
                <%= link(@current_user.email,
                  class: "hover:underline truncate",
                  to: Routes.user_settings_path(Endpoint, :edit)
                ) %>
              </li>
              <li>
                <%= link to: Routes.user_session_path(Endpoint, :delete),
                     method: :delete,
                     data: [confirm: dgettext("prompts", "Are you sure you want to log out?")] do %>
                  <i class="fas fa-sign-out-alt"></i>
                <% end %>
              </li>
              <%= if @current_user.role == :admin and function_exported?(Routes, :live_dashboard_path, 2) do %>
                <li>
                  <%= link to: Routes.live_dashboard_path(Endpoint, :home) do %>
                    <i class="fas fa-tachometer-alt"></i>
                  <% end %>
                </li>
              <% end %>
            <% else %>
              <%= if Accounts.allow_registration?() do %>
                <li>
                  <%= link(dgettext("actions", "Register"),
                    class: "hover:underline",
                    to: Routes.user_registration_path(Endpoint, :new)
                  ) %>
                </li>
              <% end %>
              <li>
                <%= link(dgettext("actions", "Log in"),
                  class: "hover:underline",
                  to: Routes.user_session_path(Endpoint, :new)
                ) %>
              </li>
            <% end %>
          </ul>
        </div>
      </nav>
    </header>
    """
  end
end
