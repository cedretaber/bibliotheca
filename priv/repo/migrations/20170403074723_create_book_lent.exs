defmodule Bibliotheca.Repo.Migrations.CreateBookLent do
  use Ecto.Migration

  def change do
    create table(:books_lent) do
      add :book_id, references(:books, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps updated_at: false
    end
    create index(:books_lent, [:book_id])
    create index(:books_lent, [:user_id])

  end
end
