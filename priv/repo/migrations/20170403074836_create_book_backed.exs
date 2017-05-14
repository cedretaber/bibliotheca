defmodule Bibliotheca.Repo.Migrations.CreateBookBacked do
  use Ecto.Migration

  def change do
    create table(:books_backed) do
      add :book_lent_id, references(:books_lent, on_delete: :delete_all), null: false

      timestamps updated_at: false
    end
    create index(:books_backed, [:book_lent_id])

  end
end
