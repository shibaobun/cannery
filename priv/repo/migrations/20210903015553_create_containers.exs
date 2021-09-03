defmodule Cannery.Repo.Migrations.CreateContainers do
  use Ecto.Migration

  def change do
    create table(:containers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :desc, :string
      add :type, :string
      add :location, :string
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:containers, [:user_id])
  end
end
