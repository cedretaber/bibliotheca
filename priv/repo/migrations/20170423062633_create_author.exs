defmodule Bibliotheca.Repo.Migrations.CreateAuthor do
  use Ecto.Migration

  def change do
    create table(:authors) do
      add :name, :string, null: false

      timestamps updated_at: false
    end
  end
end
