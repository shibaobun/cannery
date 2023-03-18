defmodule CanneryWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.
  """
  use Phoenix.Component
  import CanneryWeb.{Gettext, ViewHelpers}
  alias Cannery.{Accounts, Ammo, Ammo.AmmoGroup}
  alias Cannery.Accounts.{Invite, Invites, User}
  alias Cannery.{Containers, Containers.Container, Tags.Tag}
  alias CanneryWeb.{Endpoint, HomeLive}
  alias CanneryWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView.{JS, Rendered}

  embed_templates "core_components/*"

  attr :title_content, :string, default: nil
  attr :current_user, User, default: nil

  def topbar(assigns)

  attr :return_to, :string, required: true
  slot(:inner_block)

  @doc """
  Renders a live component inside a modal.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <.modal return_to={Routes.<%= schema.singular %>_index_path(Endpoint, :index)}>
        <.live_component
          module={<%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>Live.FormComponent}
          id={@<%= schema.singular %>.id || :new}
          title={@page_title}
          action={@live_action}
          return_to={Routes.<%= schema.singular %>_index_path(Endpoint, :index)}
          <%= schema.singular %>: @<%= schema.singular %>
        />
      </.modal>
  """
  def modal(assigns)

  defp hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(to: "#modal", transition: "fade-out")
    |> JS.hide(to: "#modal-bg", transition: "fade-out")
    |> JS.hide(to: "#modal-content", transition: "fade-out-scale")
  end

  attr :action, :string, required: true
  attr :value, :boolean, required: true
  attr :id, :string, default: nil
  slot(:inner_block)

  @doc """
  A toggle button element that can be directed to a liveview or a
  live_component's `handle_event/3`.

  ## Examples

  <.toggle_button action="my_liveview_action" value={@some_value}>
    <span>Toggle me!</span>
  </.toggle_button>
  <.toggle_button action="my_live_component_action" target={@myself} value={@some_value}>
    <span>Whatever you want</span>
  </.toggle_button>
  """
  def toggle_button(assigns)

  attr :container, Container, required: true
  slot(:tag_actions)
  slot(:inner_block)

  @spec container_card(assigns :: map()) :: Rendered.t()
  def container_card(assigns)

  attr :tag, Tag, required: true
  slot(:inner_block, required: true)

  def tag_card(assigns)

  attr :tag, Tag, required: true

  def simple_tag_card(assigns)

  attr :ammo_group, AmmoGroup, required: true
  attr :show_container, :boolean, default: false
  slot(:inner_block)

  def ammo_group_card(assigns)

  attr :user, User, required: true
  slot(:inner_block, required: true)

  def user_card(assigns)

  attr :invite, Invite, required: true
  attr :current_user, User, required: true
  slot(:inner_block)
  slot(:code_actions)

  def invite_card(%{invite: invite, current_user: current_user} = assigns) do
    assigns = assigns |> assign(:use_count, Invites.get_use_count(invite, current_user))

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
        <%= if @code_actions, do: render_slot(@code_actions) %>
      </div>

      <div :if={@inner_block} class="flex space-x-4 justify-center items-center">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr :content, :string, required: true
  attr :filename, :string, default: "qrcode", doc: "filename without .png extension"
  attr :image_class, :string, default: "w-64 h-max"
  attr :width, :integer, default: 384, doc: "width of png to generate"

  @doc """
  Creates a downloadable QR Code element
  """
  def qr_code(assigns)

  attr :date, :any, required: true, doc: "A `Date` struct or nil"

  @doc """
  Phoenix.Component for a <date> element that renders the Date in the user's
  local timezone with Alpine.js
  """
  def date(assigns)

  attr :datetime, :any, required: true, doc: "A `DateTime` struct or nil"

  @doc """
  Phoenix.Component for a <time> element that renders the naivedatetime in the
  user's local timezone with Alpine.js
  """
  def datetime(assigns)

  @spec cast_datetime(NaiveDateTime.t() | nil) :: String.t()
  defp cast_datetime(%NaiveDateTime{} = datetime) do
    datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601(:extended)
  end

  defp cast_datetime(_datetime), do: ""
end
