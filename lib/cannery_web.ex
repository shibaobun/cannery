defmodule CanneryWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use CanneryWeb, :controller
      use CanneryWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: CanneryWeb

      import Plug.Conn
      import CanneryWeb.Gettext
      alias CanneryWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/cannery_web/templates",
        namespace: CanneryWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {CanneryWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
      use Phoenix.Channel
      # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
      import CanneryWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
      import Phoenix.View

      # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
      import CanneryWeb.{ErrorHelpers, Gettext, LiveHelpers, ViewHelpers}
      alias CanneryWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
