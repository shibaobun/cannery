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
          <.link
            navigate={Routes.live_path(Endpoint, HomeLive)}
            class="inline mx-2 my-1 leading-5 text-xl text-white"
          >
            <img
              src={Routes.static_path(Endpoint, "/images/cannery.svg")}
              alt={gettext("Cannery logo")}
              class="inline-block h-8 mx-1"
            />
            <h1 class="inline hover:underline">Cannery</h1>
          </.link>

          <%= if @title_content do %>
            <span class="mx-2 my-1">
              |
            </span>
            <%= @title_content %>
          <% end %>
        </div>

        <hr class="mb-2 sm:hidden hr-light" />

        <ul class="flex flex-row flex-wrap justify-center items-center
          text-lg text-white text-ellipsis">
          <%= if @current_user do %>
            <li class="mx-2 my-1">
              <.link
                navigate={Routes.tag_index_path(Endpoint, :index)}
                class="text-primary-600 text-white hover:underline"
              >
                <%= gettext("Tags") %>
              </.link>
            </li>
            <li class="mx-2 my-1">
              <.link
                navigate={Routes.container_index_path(Endpoint, :index)}
                class="text-primary-600 text-white hover:underline"
              >
                <%= gettext("Containers") %>
              </.link>
            </li>
            <li class="mx-2 my-1">
              <.link
                navigate={Routes.ammo_type_index_path(Endpoint, :index)}
                class="text-primary-600 text-white hover:underline"
              >
                <%= gettext("Catalog") %>
              </.link>
            </li>
            <li class="mx-2 my-1">
              <.link
                navigate={Routes.ammo_group_index_path(Endpoint, :index)}
                class="text-primary-600 text-white hover:underline"
              >
                <%= gettext("Ammo") %>
              </.link>
            </li>
            <li class="mx-2 my-1">
              <.link
                navigate={Routes.range_index_path(Endpoint, :index)}
                class="text-primary-600 text-white hover:underline"
              >
                <%= gettext("Range") %>
              </.link>
            </li>
            <%= if @current_user.role == :admin do %>
              <li class="mx-2 my-1">
                <.link
                  navigate={Routes.invite_index_path(Endpoint, :index)}
                  class="text-primary-600 text-white hover:underline"
                >
                  <%= gettext("Invites") %>
                </.link>
              </li>
            <% end %>
            <li class="mx-2 my-1">
              <.link
                navigate={Routes.user_settings_path(Endpoint, :edit)}
                class="text-primary-600 text-white hover:underline truncate"
              >
                <%= @current_user.email %>
              </.link>
            </li>
            <li class="mx-2 my-1">
              <.link
                href={Routes.user_session_path(Endpoint, :delete)}
                method="delete"
                data-confirm={dgettext("prompts", "Are you sure you want to log out?")}
              >
                <i class="fas fa-sign-out-alt"></i>
              </.link>
            </li>
            <%= if @current_user.role == :admin and function_exported?(Routes, :live_dashboard_path, 2) do %>
              <li class="mx-2 my-1">
                <.link
                  navigate={Routes.live_dashboard_path(Endpoint, :home)}
                  class="text-primary-600 text-white hover:underline"
                >
                  <i class="fas fa-gauge"></i>
                </.link>
              </li>
            <% end %>
          <% else %>
            <li :if={Accounts.allow_registration?()} class="mx-2 my-1">
              <.link
                navigate={Routes.user_registration_path(Endpoint, :new)}
                class="text-primary-600 text-white hover:underline truncate"
              >
                <%= dgettext("actions", "Register") %>
              </.link>
            </li>
            <li class="mx-2 my-1">
              <.link
                navigate={Routes.user_session_path(Endpoint, :new)}
                class="text-primary-600 text-white hover:underline truncate"
              >
                <%= dgettext("actions", "Log in") %>
              </.link>
            </li>
          <% end %>
        </ul>
      </div>
    </nav>
    """
  end
end
