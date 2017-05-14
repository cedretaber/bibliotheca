defmodule Bibliotheca.Repo.Migrations.CreateBookAuthor do
  use Ecto.Migration

  def change do
    create table(:book_authors) do
      add :book_id, references(:books, on_delete: :delete_all), null: false
      add :author_id, references(:authors, on_delete: :delete_all), null: false
    end
  end
end
