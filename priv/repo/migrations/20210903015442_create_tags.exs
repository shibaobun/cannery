defmodule Cannery.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :bg_color, :string
      add :text_color, :string
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:tags, [:user_id])
  end
end
