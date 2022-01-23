import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :cannery, Cannery.Repo,
  url:
    System.get_env("TEST_DATABASE_URL") ||
      "ecto://postgres:postgres@localhost/cannery_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cannery, CanneryWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4002],
  secret_key_base: "S3qq9QtUdsFtlYej+HTjAVN95uP5i5tf2sPYINWSQfCKJghFj2B1+wTAoljZyHOK",
  server: false

# In test we don't send emails.
config :cannery, Cannery.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
