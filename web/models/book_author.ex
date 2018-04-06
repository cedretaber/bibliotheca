defmodule Bibliotheca.BookAuthor do
  use Bibliotheca.Web, :model

  @primary_key false

  schema "book_authors" do
    belongs_to(:book, Bibliotheca.Book, primary_key: true)
    belongs_to(:author, Bibliotheca.Author, primary_key: true)

    timestamps(updated_at: false)
  end
end
