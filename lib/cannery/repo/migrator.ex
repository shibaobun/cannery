defmodule Cannery.Repo.Migrator do
  @moduledoc """
  Genserver to automatically run migrations in prod env
  """

  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], [])
  end

  def init(_opts) do
    migrate!()
    {:ok, nil}
  end

  def migrate! do
    path = Application.app_dir(:cannery, "priv/repo/migrations")
    Ecto.Migrator.run(Cannery.Repo, path, :up, all: true)
  end
end
