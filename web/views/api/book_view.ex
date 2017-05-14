defmodule Bibliotheca.Api.BookView do
  use Bibliotheca.Web, :view

  def render("index.json", %{books: books}), do:
    render_many(books, __MODULE__, "book.json")

  def render("book.json", %{book: book}), do:
    %{id: book.id,
      name: book.name,
      author: book.author,
      publisher: book.publisher,
      publishedAt: book.published_at,
      isbn: book.isbn}
end