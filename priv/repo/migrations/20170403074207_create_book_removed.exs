defmodule Bibliotheca.Repo.Migrations.CreateBookRemoved do
  use Ecto.Migration

  def change do
    create table(:books_removed) do
      add :book_id, references(:books, on_delete: :delete_all), null: false

      timestamps updated_at: false
    end
    create index(:books_removed, [:book_id])

  end
end
