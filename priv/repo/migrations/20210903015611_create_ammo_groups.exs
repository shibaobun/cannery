defmodule Cannery.Repo.Migrations.CreateAmmoGroups do
  use Ecto.Migration

  def change do
    create table(:ammo_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :count, :integer
      add :price_paid, :float
      add :notes, :text
      add :tag_id, references(:tags, on_delete: :nothing, type: :binary_id)
      add :ammo_type_id, references(:ammo_types, on_delete: :nothing, type: :binary_id)
      add :container_id, references(:containers, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:ammo_groups, [:tag_id])
    create index(:ammo_groups, [:ammo_type_id])
    create index(:ammo_groups, [:container_id])
    create index(:ammo_groups, [:user_id])
  end
end
