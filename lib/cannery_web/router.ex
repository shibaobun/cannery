defmodule CanneryWeb.Router do
  use CanneryWeb, :router
  import Phoenix.LiveDashboard.Router
  import CanneryWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CanneryWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :put_user_locale, default: Application.compile_env(:gettext, :default_locale, "en_US")
  end

  defp put_user_locale(%{assigns: %{current_user: %{locale: locale}}} = conn, default: default) do
    Gettext.put_locale(locale || default)
    conn |> put_session(:locale, locale || default)
  end

  defp put_user_locale(conn, default: default) do
    Gettext.put_locale(default)
    conn |> put_session(:locale, default)
  end

  pipeline :require_admin do
    plug :require_role, role: :admin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CanneryWeb do
    pipe_through :browser

    live "/", HomeLive
  end

  ## Authentication routes

  scope "/", CanneryWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", CanneryWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    delete "/users/settings/:id", UserSettingsController, :delete
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
    get "/export/:mode", ExportController, :export

    live "/tags", TagLive.Index, :index
    live "/tags/new", TagLive.Index, :new
    live "/tags/:id/edit", TagLive.Index, :edit

    live "/catalog", AmmoTypeLive.Index, :index
    live "/catalog/new", AmmoTypeLive.Index, :new
    live "/catalog/clone/:id", AmmoTypeLive.Index, :clone
    live "/catalog/edit/:id", AmmoTypeLive.Index, :edit
    live "/catalog/search/:search", AmmoTypeLive.Index, :search

    live "/type/:id", AmmoTypeLive.Show, :show
    live "/type/:id/edit", AmmoTypeLive.Show, :edit
    live "/type/:id/table", AmmoTypeLive.Show, :table

    live "/containers", ContainerLive.Index, :index
    live "/containers/new", ContainerLive.Index, :new
    live "/containers/edit/:id", ContainerLive.Index, :edit
    live "/containers/clone/:id", ContainerLive.Index, :clone
    live "/containers/edit_tags/:id", ContainerLive.Index, :edit_tags
    live "/containers/search/:search", ContainerLive.Index, :search

    live "/container/:id", ContainerLive.Show, :show
    live "/container/edit/:id", ContainerLive.Show, :edit
    live "/container/edit_tags/:id", ContainerLive.Show, :edit_tags

    live "/ammo", AmmoGroupLive.Index, :index
    live "/ammo/new", AmmoGroupLive.Index, :new
    live "/ammo/edit/:id", AmmoGroupLive.Index, :edit
    live "/ammo/clone/:id", AmmoGroupLive.Index, :clone
    live "/ammo/add_shot_group/:id", AmmoGroupLive.Index, :add_shot_group
    live "/ammo/move/:id", AmmoGroupLive.Index, :move
    live "/ammo/search/:search", AmmoGroupLive.Index, :search

    live "/ammo/show/:id", AmmoGroupLive.Show, :show
    live "/ammo/show/edit/:id", AmmoGroupLive.Show, :edit
    live "/ammo/show/add_shot_group/:id", AmmoGroupLive.Show, :add_shot_group
    live "/ammo/show/move/:id", AmmoGroupLive.Show, :move
    live "/ammo/show/:id/edit/:shot_group_id", AmmoGroupLive.Show, :edit_shot_group

    live "/range", RangeLive.Index, :index
    live "/range/:id/edit", RangeLive.Index, :edit
    live "/range/:id/add_shot_group", RangeLive.Index, :add_shot_group
  end

  scope "/", CanneryWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    live_dashboard "/dashboard", metrics: CanneryWeb.Telemetry, ecto_repos: [Cannery.Repo]

    live "/invites", InviteLive.Index, :index
    live "/invites/new", InviteLive.Index, :new
    live "/invites/:id/edit", InviteLive.Index, :edit
  end

  scope "/", CanneryWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    scope "/dev" do
      get "/preview/:id", CanneryWeb.EmailController, :preview
    end
  end
end
