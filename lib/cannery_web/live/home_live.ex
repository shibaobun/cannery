defmodule CanneryWeb.HomeLive do
  @moduledoc """
  Liveview for the home page
  """

  use CanneryWeb, :live_view
  alias Cannery.Accounts
  alias CanneryWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    admins = Accounts.list_users_by_role(:admin)
    socket = socket |> assign(page_title: "Home", query: "", results: %{}, admins: admins)
    {:ok, socket}
  end

  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, socket |> assign(results: search(query), query: query)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    case search(query) do
      %{^query => vsn} ->
        {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

      _no_query ->
        {:noreply,
         socket
         |> put_flash(:error, "No dependencies found matching \"#{query}\"")
         |> assign(results: %{}, query: query)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto px-8 sm:px-16 flex flex-col justify-center items-center text-center space-y-4 max-w-3xl">
      <img
        src={Routes.static_path(Endpoint, "/images/cannery.svg")}
        alt={gettext("Cannery logo")}
        class="inline-block w-32 hover:-mt-2 hover:mb-2 transition-all duration-500 ease-in-out"
        title={gettext("isn't he cute >:3")}
      />

      <h1 class="title text-primary-600 text-2xl">
        <%= gettext("Welcome to %{name}", name: "Cannery") %>
      </h1>

      <h2 class="title text-primary-600 text-lg">
        <%= gettext("The self-hosted firearm tracker website") %>
      </h2>

      <hr class="hr" />

      <ul class="flex flex-col space-y-4 text-center">
        <li class="flex flex-col justify-center items-center
          space-y-2">
          <b class="whitespace-nowrap">
            <%= gettext("Easy to Use:") %>
          </b>
          <p>
            <%= gettext(
              "%{name} lets you easily keep an eye on your ammo levels before and after range day",
              name: "Cannery"
            ) %>
          </p>
        </li>
        <li class="flex flex-col justify-center items-center
          space-y-2">
          <b class="whitespace-nowrap">
            <%= gettext("Secure:") %>
          </b>
          <p>
            <%= gettext("Self-host your own instance, or use an instance from someone you trust.") %>
            <%= gettext("Your data stays with you, period") %>
          </p>
        </li>
        <li class="flex flex-col justify-center items-center
          space-y-2">
          <b class="whitespace-nowrap">
            <%= gettext("Simple:") %>
          </b>
          <p>
            <%= gettext("Access from any internet-capable device") %>
          </p>
        </li>
      </ul>

      <hr class="hr" />

      <ul class="flex flex-col space-y-2 text-center justify-center">
        <h2 class="title text-primary-600 text-lg">
          <%= gettext("Instance Information") %>
        </h2>

        <li class="flex flex-col justify-center space-x-2">
          <b>
            <%= gettext("Admins:") %>
          </b>
          <p>
            <%= if @admins |> Enum.empty?() do %>
              <.link
                href={Routes.user_registration_path(CanneryWeb.Endpoint, :new)}
                class="hover:underline"
              >
                <%= dgettext("prompts", "Register to setup %{name}", name: "Cannery") %>
              </.link>
            <% else %>
              <div class="flex flex-wrap justify-center space-x-2">
                <%= for admin <- @admins do %>
                  <a class="hover:underline" href={"mailto:#{admin.email}"}>
                    <%= admin.email %>
                  </a>
                <% end %>
              </div>
            <% end %>
          </p>
        </li>

        <li class="flex flex-row justify-center space-x-2">
          <b>Registration:</b>
          <p>
            <%= Application.get_env(:cannery, CanneryWeb.Endpoint)[:registration]
            |> case do
              "public" -> gettext("Public Signups")
              _ -> gettext("Invite Only")
            end %>
          </p>
        </li>

        <li class="flex flex-row justify-center items-center space-x-2">
          <b>Version:</b>
          <.link
            href="https://gitea.bubbletea.dev/shibao/cannery/src/branch/stable/CHANGELOG.md"
            class="flex flex-row justify-center items-center space-x-2 hover:underline"
            target="_blank"
            rel="noopener noreferrer"
          >
            <p>0.7.1</p>
            <i class="fas fa-md fa-info-circle"></i>
          </.link>
        </li>
      </ul>

      <hr class="hr" />

      <ul class="flex flex-col space-y-2 text-center justify-center">
        <h2 class="title text-primary-600 text-lg">
          <%= gettext("Get involved!") %>
        </h2>

        <li class="flex flex-col justify-center space-x-2">
          <.link
            class="flex flex-row justify-center items-center space-x-2 hover:underline"
            href="https://gitea.bubbletea.dev/shibao/cannery"
            target="_blank"
            rel="noopener noreferrer"
          >
            <p><%= gettext("View the source code") %></p>
            <i class="fas fa-md fa-code"></i>
          </.link>
        </li>
        <li class="flex flex-col justify-center space-x-2">
          <.link
            class="flex flex-row justify-center items-center space-x-2 hover:underline"
            href="https://weblate.bubbletea.dev/engage/cannery"
            target="_blank"
            rel="noopener noreferrer"
          >
            <p><%= gettext("Help translate") %></p>
            <i class="fas fa-md fa-language"></i>
          </.link>
        </li>
        <li class="flex flex-col justify-center space-x-2">
          <.link
            class="flex flex-row justify-center items-center space-x-2 hover:underline"
            href="https://gitea.bubbletea.dev/shibao/cannery/issues/new"
            target="_blank"
            rel="noopener noreferrer"
          >
            <p><%= gettext("Report bugs or request features") %></p>
            <i class="fas fa-md fa-spider"></i>
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  defp search(query) do
    if not CanneryWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    for {app, desc, vsn} <- Application.started_applications(),
        app = to_string(app),
        String.starts_with?(app, query) and not List.starts_with?(desc, ~c"ERTS"),
        into: %{},
        do: {app, vsn}
  end
end
