defmodule Cannery.Repo.Migrations.CreateContainerTags do
  use Ecto.Migration

  def change do
    create table(:container_tags, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :container_id, references(:containers, on_delete: :delete_all, type: :binary_id)
      add :tag_id, references(:tags, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:container_tags, [:container_id])
    create index(:container_tags, [:tag_id])
  end
end
