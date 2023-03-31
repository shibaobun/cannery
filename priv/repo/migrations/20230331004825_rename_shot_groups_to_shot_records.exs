defmodule Cannery.Repo.Migrations.RenameShotGroupsToShotRecords do
  use Ecto.Migration

  def up do
    drop index(:shot_groups, [:user_id, :pack_id])

    flush()

    rename table(:shot_groups), to: table(:shot_records)
  end

  def down do
    rename table(:shot_records), to: table(:shot_groups)

    flush()

    create index(:shot_groups, [:user_id, :pack_id])
  end
end
