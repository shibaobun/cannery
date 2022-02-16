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
    <nav role="navigation" class="mb-8 px-8 py-4 w-full bg-primary-400">
      <div class="flex flex-col sm:flex-row justify-between items-center">
        <div class="mb-4 sm:mb-0 sm:mr-8 flex flex-row justify-start items-center space-x-2">
          <%= link to: Routes.live_path(Endpoint, HomeLive) do %>
            <h1 class="mx-2 my-1 leading-5 text-xl text-white hover:underline">
              Cannery
            </h1>
          <% end %>

          <%= if @title_content do %>
            <span class="mx-2 my-1">
              |
            </span>
            <%= @title_content %>
          <% end %>
        </div>

        <hr class="mb-2 sm:hidden hr-light">

        <ul class="flex flex-row flex-wrap justify-center items-center
          text-lg text-white text-ellipsis">
          <%= if @current_user do %>
            <li class="mx-2 my-1">
              <%= link(gettext("Tags"),
                class: "hover:underline",
                to: Routes.tag_index_path(Endpoint, :index)
              ) %>
            </li>
            <li class="mx-2 my-1">
              <%= link(gettext("Containers"),
                class: "hover:underline",
                to: Routes.container_index_path(Endpoint, :index)
              ) %>
            </li>
            <li class="mx-2 my-1">
              <%= link(gettext("Ammo"),
                class: "hover:underline",
                to: Routes.ammo_type_index_path(Endpoint, :index)
              ) %>
            </li>
            <li class="mx-2 my-1">
              <%= link(gettext("Manage"),
                class: "hover:underline",
                to: Routes.ammo_group_index_path(Endpoint, :index)
              ) %>
            </li>
            <li class="mx-2 my-1">
              <%= link(gettext("Range"),
                class: "hover:underline",
                to: Routes.range_index_path(Endpoint, :index)
              ) %>
            </li>
            <%= if @current_user.role == :admin do %>
              <li class="mx-2 my-1">
                <%= link(gettext("Invites"),
                  class: "hover:underline",
                  to: Routes.invite_index_path(Endpoint, :index)
                ) %>
              </li>
            <% end %>
            <li class="mx-2 my-1">
              <%= link(@current_user.email,
                class: "hover:underline truncate",
                to: Routes.user_settings_path(Endpoint, :edit)
              ) %>
            </li>
            <li class="mx-2 my-1">
              <%= link to: Routes.user_session_path(Endpoint, :delete),
                   method: :delete,
                   data: [confirm: dgettext("prompts", "Are you sure you want to log out?")] do %>
                <i class="fas fa-sign-out-alt"></i>
              <% end %>
            </li>
            <%= if @current_user.role == :admin and function_exported?(Routes, :live_dashboard_path, 2) do %>
              <li class="mx-2 my-1">
                <%= link to: Routes.live_dashboard_path(Endpoint, :home) do %>
                  <i class="fas fa-tachometer-alt"></i>
                <% end %>
              </li>
            <% end %>
          <% else %>
            <%= if Accounts.allow_registration?() do %>
              <li class="mx-2 my-1">
                <%= link(dgettext("actions", "Register"),
                  class: "hover:underline",
                  to: Routes.user_registration_path(Endpoint, :new)
                ) %>
              </li>
            <% end %>
            <li class="mx-2 my-1">
              <%= link(dgettext("actions", "Log in"),
                class: "hover:underline",
                to: Routes.user_session_path(Endpoint, :new)
              ) %>
            </li>
          <% end %>
        </ul>
      </div>
    </nav>
    """
  end
end
