defmodule Cannery.Repo.Migrations.AddMoreIndexes do
  use Ecto.Migration

  def change do
    create unique_index(:container_tags, [:tag_id, :container_id])

    create index(:ammo_groups, [:user_id], where: "count = 0", name: :empty_ammo_groups_index)
    create index(:ammo_groups, [:user_id, :ammo_type_id])
    create index(:ammo_groups, [:user_id, :container_id])

    create index(:ammo_types, [:user_id])

    drop index(:shot_groups, [:id])
    create index(:shot_groups, [:user_id, :ammo_group_id])
  end
end
