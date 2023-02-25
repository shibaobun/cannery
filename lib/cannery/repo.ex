defmodule Cannery.Repo do
  use Ecto.Repo,
    otp_app: :cannery,
    adapter: Ecto.Adapters.Postgres
end
