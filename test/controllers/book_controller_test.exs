defmodule Bibliotheca.BookControllerTest do
  use Bibliotheca.ConnCase, async: true

  alias Bibliotheca.{Repo, Book}
  alias Bibliotheca.Api.BookView

#  @user1 %User{id: 1, email: "user1@example.com", password_digest: "password", auth_code: "ADMIN"}
#  @user2 %User{id: 2, email: "user2@example.com", password_digest: "password", auth_code: "NORMAL"}

  @book1 %Book{id: 1, title: "book1", description: "awesome book."}
  @book2 %Book{id: 2, title: "book2", description: "normal book."}
  @book3 %Book{id: 3, title: "book3", description: "awesome cool book."}

  describe "index/2" do
    test "without query all books.", %{conn: conn} do
      for book <- [@book1, @book2, @book3], do: Repo.insert! book

      conn = get(conn, "/api/books/")

      assert (json_response(conn, 200)["books"] |> Enum.sort_by(&(&1["id"]))) ==
        (BookView.render("index.json", %{ books: (for book <- [@book1, @book2, @book3], do: Repo.preload(book, :authors)) }) |> jsonise())["books"]
    end

    test "search one book" , %{conn: conn} do
      for book <- [@book1, @book2, @book3], do: Repo.insert! book

      conn = get(conn, "/api/books/?q=book2")

      assert (json_response(conn, 200)["books"] |> Enum.sort_by(&(&1["id"]))) ==
             (BookView.render("index.json", %{ books: [@book2 |> Repo.preload(:authors)] }) |> jsonise())["books"]
    end

    test "with query all books.", %{conn: conn} do
      for book <- [@book1, @book2, @book3], do: Repo.insert! book

      conn = get(conn, "/api/books/?q=book")

      assert (json_response(conn, 200)["books"] |> Enum.sort_by(&(&1["id"]))) ==
             (BookView.render("index.json", %{ books: (for book <- [@book1, @book2, @book3], do: Repo.preload(book, :authors)) }) |> jsonise())["books"]
    end

    test "search some book.", %{conn: conn} do
      for book <- [@book1, @book2, @book3], do: Repo.insert! book

      conn = get(conn, "/api/books/?q=awesome")

      assert (json_response(conn, 200)["books"] |> Enum.sort_by(&(&1["id"]))) ==
             (BookView.render("index.json", %{ books: (for book <- [@book1, @book3], do: Repo.preload(book, :authors)) }) |> jsonise())["books"]
    end
  end

  describe "show" do
    test "get a book.", %{conn: conn} do
      Repo.insert! @book1

      conn = get(conn, "/api/books/#{@book1.id}")
      assert json_response(conn, 200) == (BookView.render("show.json", %{ book: Repo.preload(@book1, :authors) }) |> jsonise())
    end

    test "get a nonexistent book.", %{conn: conn} do
      conn = get(conn, "/api/books/42")
      assert json_response(conn, 404) == %{ "error" => "Book Not Found" }
    end

    test "get a removed book.", %{conn: conn} do
      Repo.insert! @book1
      Book.remove(@book1.id)

      conn = get(conn, "/api/books/#{@book1.id}")
      assert json_response(conn, 404) == %{ "error" => "Book Not Found" }
    end
  end
end