defmodule Bibliotheca.Api.BookView do
  use Bibliotheca.Web, :view

  def render("index.json", %{books: books}), do:
    %{ books: render_many(books, __MODULE__, "book.json") }

  def render("show.json", %{book: book}), do:
    %{ book: render_one(book, __MODULE__, "book.json") }

  def render("book.json", %{book: book}), do:
    %{id: book.id,
      title: book.title,
      authors: (for author <- book.authors, do: author.name),
      description: book.description,
      imageUrl: book.image_url,
      publisher: book.publisher,
      publishedAt: book.published_at,
      pageCount: book.page_count,
      isbn: book.isbn}
end