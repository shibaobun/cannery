defmodule Cannery.Repo.Migrator do
  use GenServer
  require Logger
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], [])
  end
  
  def init(_) do
    migrate!()
    {:ok, nil}
  end
  
  def migrate! do
    path = Application.app_dir(:cannery, "priv/repo/migrations")
    Ecto.Migrator.run(Cannery.Repo, path, :up, all: true)
  end
end