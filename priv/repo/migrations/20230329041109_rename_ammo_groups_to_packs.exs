defmodule Cannery.Repo.Migrations.RenameAmmoGroupsToPacks do
  use Ecto.Migration

  def up do
    drop index(:ammo_groups, [:user_id], where: "count = 0", name: :empty_ammo_groups_index)
    drop index(:ammo_groups, [:user_id, :ammo_type_id])
    drop index(:ammo_groups, [:user_id, :container_id])

    flush()

    rename table(:ammo_groups), to: table(:packs)

    flush()

    create index(:packs, [:user_id], where: "count = 0", name: :empty_packs_index)
    create index(:packs, [:user_id, :ammo_type_id])
    create index(:packs, [:user_id, :container_id])

    rename table(:shot_groups), :ammo_group_id, to: :pack_id
  end

  def down do
    drop index(:packs, [:user_id], where: "count = 0", name: :empty_packs_index)
    drop index(:packs, [:user_id, :ammo_type_id])
    drop index(:packs, [:user_id, :container_id])

    flush()

    rename table(:packs), to: table(:ammo_groups)

    flush()

    create index(:ammo_groups, [:user_id], where: "count = 0", name: :empty_ammo_groups_index)
    create index(:ammo_groups, [:user_id, :ammo_type_id])
    create index(:ammo_groups, [:user_id, :container_id])

    rename table(:shot_groups), :pack_id, to: :ammo_group_id
  end
end
