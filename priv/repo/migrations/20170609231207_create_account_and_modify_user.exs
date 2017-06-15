defmodule Bibliotheca.Repo.Migrations.CreateAccountAndModifyUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :deleted_at
    end

    create table(:accounts) do
      add :name, :string, null: false
      add :deleted_at, :naive_datetime

      timestamps()
    end
    create unique_index(:accounts, [:name])

    create table(:user_accounts, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false, primary_key: true
      add :account_id, references(:accounts, on_delete: :delete_all), null: false, primary_key: true

      timestamps updated_at: false
    end

    drop index(:books_lent, [:user_id])
    alter table(:books_lent) do
      remove :user_id
      add :account_id, references(:accounts, on_delete: :delete_all), null: false
    end
    create index(:books_lent, [:account_id])

    drop index(:books_backed, [:book_lent_id])
    drop table(:books_backed)
    create table(:books_backed, primary_key: false) do
      add :book_lent_id, references(:books_lent, on_delete: :delete_all), null: false, primary_key: true

      timestamps updated_at: false
    end

    drop table(:books_removed)
    create table(:books_removed, primary_key: false) do
      add :book_id, references(:books, on_delete: :delete_all), null: false, primary_key: true

      timestamps updated_at: false
    end

    drop table(:book_authors)
    create table(:book_authors, primary_key: false) do
      add :book_id, references(:books, on_delete: :delete_all), null: false, primary_key: true
      add :author_id, references(:authors, on_delete: :delete_all), null: false, primary_key: true

      timestamps updated_at: false
    end
  end
end
