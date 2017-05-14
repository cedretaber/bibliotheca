defmodule Bibliotheca.Repo.Migrations.CreateBook do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :title, :string, null: false
      add :description, :text
      add :publisher, :string
      add :image_url, :string
      add :isbn, :string, size: 13
      add :page_count, :integer
      add :published_at, :date

      timestamps updated_at: false
    end

    create index(:books, :title)
  end
end
