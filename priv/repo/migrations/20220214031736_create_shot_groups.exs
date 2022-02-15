defmodule Cannery.Repo.Migrations.CreateShotGroups do
  use Ecto.Migration

  def change do
    create table(:shot_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :count, :integer
      add :notes, :string
      add :date, :date

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :ammo_group_id, references(:ammo_groups, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:shot_groups, [:id])
    create index(:shot_groups, [:user_id])
    create index(:shot_groups, [:ammo_group_id])

    alter table(:ammo_groups) do
      add :staged, :boolean, null: false, default: false
    end
  end
end
