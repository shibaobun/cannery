# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

database_url =
  System.get_env("DATABASE_URL") ||
    "ecto://postgres:postgres@cannery-db/cannery"

config :cannery, Cannery.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

host = System.get_env("HOST") || "localhost"

config :cannery, CanneryWeb.Endpoint,
  url: [host: host],
  http: [
    port: String.to_integer(System.get_env("PORT") || "80"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base,
  server: true,
  registration: System.get_env("REGISTRATION") || "invite"
