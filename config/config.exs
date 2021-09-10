# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :cannery,
  ecto_repos: [Cannery.Repo]

# Configures the endpoint
config :cannery, CanneryWeb.Endpoint,
  url: [host: System.get_env("HOST") || "localhost"],
  http: [port: String.to_integer(System.get_env("PORT") || "80")],
  secret_key_base: "KH59P0iZixX5gP/u+zkxxG8vAAj6vgt0YqnwEB5JP5K+E567SsqkCz69uWShjE7I",
  render_errors: [view: CanneryWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Cannery.PubSub,
  live_view: [signing_salt: "zOLgd3lr"],
  registration: System.get_env("REGISTRATION") || "invite"

config :cannery, :generators,
  migration: true,
  binary_id: true,
  sample_binary_id: "11111111-1111-1111-1111-111111111111"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
