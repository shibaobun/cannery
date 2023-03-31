defmodule Cannery.Repo.Migrations.RenameShotGroupsToShotRecords do
  use Ecto.Migration

  def change do
    rename table(:shot_groups), to: table(:shot_records)
  end
end
