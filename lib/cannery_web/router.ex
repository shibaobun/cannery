defmodule CanneryWeb.Router do
  use CanneryWeb, :router

  import CanneryWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CanneryWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CanneryWeb do
    pipe_through :browser

    live "/", PageLive, :index
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: CanneryWeb.Telemetry, ecto_repos: [Cannery.Repo]
    end
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
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
    
    live "/tags", TagLive.Index, :index
    live "/tags/new", TagLive.Index, :new
    live "/tags/:id/edit", TagLive.Index, :edit

    live "/tags/:id", TagLive.Show, :show
    live "/tags/:id/show/edit", TagLive.Show, :edit
    
    live "/ammo_types", AmmoTypeLive.Index, :index
    live "/ammo_types/new", AmmoTypeLive.Index, :new
    live "/ammo_types/:id/edit", AmmoTypeLive.Index, :edit

    live "/ammo_types/:id", AmmoTypeLive.Show, :show
    live "/ammo_types/:id/show/edit", AmmoTypeLive.Show, :edit
    
    live "/containers", ContainerLive.Index, :index
    live "/containers/new", ContainerLive.Index, :new
    live "/containers/:id/edit", ContainerLive.Index, :edit

    live "/containers/:id", ContainerLive.Show, :show
    live "/containers/:id/show/edit", ContainerLive.Show, :edit
    
    live "/ammo_groups", AmmoGroupLive.Index, :index
    live "/ammo_groups/new", AmmoGroupLive.Index, :new
    live "/ammo_groups/:id/edit", AmmoGroupLive.Index, :edit

    live "/ammo_groups/:id", AmmoGroupLive.Show, :show
    live "/ammo_groups/:id/show/edit", AmmoGroupLive.Show, :edit
  end

  scope "/", CanneryWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end
end
