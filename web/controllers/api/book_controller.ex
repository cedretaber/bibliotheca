defmodule Bibliotheca.Api.BookController do
  use Bibliotheca.Web, :controller

  alias Bibliotheca.{Book, BookLent}

  @book_not_found "Book Not Found"

  plug :scrub_params, "book" when action in [:create]

  def index(conn, %{"q" => q}), do:
    render conn, :index, books: Book.search(q)
  def index(conn, _param), do:
    index(conn, %{"q" => ""})

  def show(conn, %{"id" => id}) do
    case Book.find(id) do
      nil -> book_not_found(conn)
      book -> render conn, :show, book: book
    end
  end

  def create(conn, %{"book" => book_param}), do:
    show_book conn, Book.create(book_param)

  def lend(conn, %{"book_id" => book_id}), do:
    resp_no_contents conn, BookLent.lend(conn.assigns[:current_user].id, book_id)

  def back(conn, %{"book_id" => book_id}), do:
    resp_no_contents conn, BookLent.back(conn.assigns[:current_user].id, book_id)

  def remove(conn, %{"id" => id}), do:
    resp_no_contents conn, Book.remove(id)

  defp show_book(conn, ret) do
    case ret do
      {:ok, book} -> render conn, :show, book: book
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{ errors: extract_errors(changeset)})
      nil -> book_not_found(conn)
    end
  end

  defp resp_no_contents(conn, ret) do
    case ret do
      {:ok, _} -> send_resp(conn, 204, "")
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{ errors: extract_errors(changeset)})
    end
  end

  defp extract_errors(changeset), do:
    for {key, {message, details}} <- changeset.errors, do:
      %{ key => %{ message: message, details: (for {key, value} <- details, do: %{ key => value }) } }

  defp book_not_found(conn) do
    conn
    |> put_status(404)
    |> json(%{ error: @book_not_found })
  end
end