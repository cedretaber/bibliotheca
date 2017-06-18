defmodule Bibliotheca.Api.BookController do
  use Bibliotheca.Web, :controller

  import Bibliotheca.Helpers.ErrorExtractor
  import Bibliotheca.Plugs.CaseConverter, only: [conv_case: 2]

  alias Bibliotheca.{Book, BookLent}

  @book_not_found "Book Not Found"

  plug :scrub_params, "book" when action in [:create]
  plug :conv_case when action in [:create]

  def index(conn, %{"q" => q}), do:
    render conn, :index, books: Book.search(q)
  def index(conn, _param), do:
    index conn, %{"q" => ""}

  def lending(conn, %{"id" => id}), do:
    json conn, %{account_id: (account = BookLent.lending_account id) && account.id}

  def show(conn, %{"id" => id}) do
    book = Book.find id
    show_book conn, (if is_nil(book), do: nil, else: {:ok, book})
  end

  def create(conn, %{"book" => book_param}), do:
    show_book conn, Book.create(book_param)

  def remove(conn, %{"id" => id}), do:
    resp_no_contents conn, Book.remove(id)

  defp show_book(conn, ret) do
    case ret do
      {:ok, book}         -> render conn, :show, book: book
      {:error, changeset} -> client_error conn, changeset
      nil                 -> book_not_found conn
    end
  end

  defp resp_no_contents(conn, ret) do
    case ret do
      {:ok, _}            -> send_resp conn, 204, ""
      {:error, changeset} -> client_error conn, changeset
      nil                 -> book_not_found conn
    end
  end

  defp client_error(conn, changeset), do:
    conn
    |> put_status(400)
    |> json(%{ errors: extract_errors(changeset)})

  defp book_not_found(conn), do:
    conn
    |> put_status(404)
    |> json(%{ error: @book_not_found })
end