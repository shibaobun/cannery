defmodule Cannery.Repo.Migrations.AddLotNumberToPacks do
  use Ecto.Migration

  def change do
    alter table(:packs) do
      add :lot_number, :string
    end
  end
end
