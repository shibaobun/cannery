defmodule Cannery.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Cannery.ErrorReporter

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Cannery.Repo,
      # Start the Telemetry supervisor
      CanneryWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Cannery.PubSub},
      # Start the Endpoint (http/https)
      CanneryWeb.Endpoint,
      # Add Oban
      {Oban, oban_config()},
      Cannery.Repo.Migrator
      # Start a worker by calling: Cannery.Worker.start_link(arg)
      # {Cannery.Worker, arg}
    ]

    # Oban events logging https://hexdocs.pm/oban/Oban.html#module-reporting-errors
    :ok =
      :telemetry.attach_many(
        "oban-logger",
        [
          [:oban, :job, :exception],
          [:oban, :job, :start],
          [:oban, :job, :stop]
        ],
        &ErrorReporter.handle_event/4,
        []
      )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cannery.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CanneryWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config do
    Application.fetch_env!(:cannery, Oban)
  end
end
