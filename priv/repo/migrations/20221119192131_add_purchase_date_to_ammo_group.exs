defmodule Cannery.Repo.Migrations.AddPurchaseDateToAmmoGroup do
  use Ecto.Migration

  def up do
    alter table(:ammo_groups) do
      add :purchased_on, :date
    end

    flush()

    execute("UPDATE ammo_groups SET purchased_on = inserted_at::DATE WHERE purchased_on IS NULL")
  end

  def down do
    alter table(:ammo_groups) do
      remove :purchased_on
    end
  end
end
