defmodule Cannery.Repo.Migrations.CreateContainers do
  use Ecto.Migration

  def change do
    create table(:containers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :desc, :text
      add :type, :string
      add :location, :text

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:containers, [:user_id])
  end
end
