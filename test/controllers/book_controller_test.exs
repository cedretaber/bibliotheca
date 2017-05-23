defmodule Bibliotheca.BookControllerTest do
  use Bibliotheca.ConnCase, async: true

  alias Bibliotheca.{Repo, Book, BookLent, User}
  alias Bibliotheca.Api.BookView

#  @user1 @user
  @user2 %User{id: 2, email: "user2@example.com", password_digest: "password", auth_code: "NORMAL"}
  @user3 %User{ @user2 | id: 3, email: "user3@example.com" }

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

  describe "create" do
    test "create a book.", %{conn: conn} do
      params =
        %{title: "book1",
          description: "An awesome book!",
          authors: ["author1", "author2", "author3"],
          publisher: "Pub co., ltd.",
          image_url: "http://example.com/sample.png",
          isbn: "123456789012X",
          page_count: 334,
          published_at: "2010-04-01"}

      conn = post(conn, "/api/books", %{ book: params })

      book = Repo.get_by(Book, title: params[:title]) |> Repo.preload(:authors)

      for attr <- ~w(title description publisher image_url isbn page_count)a, do:
        assert({:ok, params[attr]} == Map.fetch(book, attr))
      assert params[:authors] == (for author <- book.authors, do: author.name)
      assert ~D[2010-04-01] == book.published_at

      assert json_response(conn, 200) == (BookView.render("show.json", %{ book: book }) |> jsonise())
    end

    test "create a minimal book.", %{conn: conn} do
      params = %{title: "book2"}

      conn = post(conn, "/api/books", %{ book: params })

      book = Repo.get_by(Book, title: params[:title]) |> Repo.preload(:authors)

      assert params[:title] == book.title
      assert [] == book.authors
      for attr <- ~w(description publisher image_url isbn page_count published_at)a, do:
        assert({:ok, nil} == Map.fetch(book, attr))

      assert json_response(conn, 200) == (BookView.render("show.json", %{ book: book }) |> jsonise())
    end

    test "create an invalid book.", %{conn: conn} do
      params = %{}

      conn = post(conn, "/api/books", %{ book: params })

      assert json_response(conn, 400) == (%{ errors: [%{ title: %{ message: "can't be blank", details: [%{validation: :required}] } }] } |> jsonise())
    end
  end

  describe "lend" do
    test "lent a book by normal user.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @book1
      assert BookLent.lentable_book(@book1.id) == :ok

      conn = conn
        |> login_user(@user2)
        |> get("/api/books/lend/#{@book1.id}")

      assert conn.status == 204
      assert BookLent.lending_user(@book1.id).id == @user2.id
    end

    test "lent an nonexistent book by normal user.", %{conn: conn} do
      Repo.insert! @user2

      book_id = 42
      assert {:error, _} = BookLent.lentable_book(book_id)

      conn = conn
        |> login_user(@user2)
        |> get("/api/books/lend/#{book_id}")

      assert json_response(conn, 400) == (%{ errors: [%{ book: %{ message: "Invalid book id.", details: [] } }] } |> jsonise())
    end

    test "lent a book which is already lent by normal user.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @user3
      Repo.insert! @book1
      assert {:ok, _} = BookLent.lend(@user3.id, @book1.id)
      assert BookLent.lending_user(@book1.id).id == @user3.id

      conn = conn
        |> login_user(@user2)
        |> get("/api/books/lend/#{@book1.id}")

      assert json_response(conn, 400) == (%{ errors: [%{ book: %{ message: "The book is already lent.", details: [] } }] } |> jsonise())
    end
  end

  describe "back" do
    test "back a book lent by normal user.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @book1
      assert {:ok, _} = BookLent.lend(@user2.id, @book1.id)
      assert BookLent.lending_user(@book1.id).id == @user2.id

      conn = conn
        |> login_user(@user2)
        |> delete("/api/books/back/#{@book1.id}")

      assert conn.status == 204
      refute BookLent.lending_user(@book1.id)
      assert BookLent.lentable_book(@book1.id) == :ok
    end

    test "back a book which is not lent.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @book1
      refute BookLent.lending_user(@book1.id)

      conn = conn
        |> login_user(@user2)
        |> delete("/api/books/back/#{@book1.id}")

      assert json_response(conn, 400) == (%{ errors: [%{ book_lent: %{ message: "Book not lent.", details: [] } }] } |> jsonise())
    end

    test "back a book which is lent by another user.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @user3
      Repo.insert! @book1
      assert {:ok, _} = BookLent.lend(@user3.id, @book1.id)
      assert BookLent.lending_user(@book1.id).id == @user3.id

      conn = conn
        |> login_user(@user2)
        |> delete("/api/books/back/#{@book1.id}")

      assert json_response(conn, 400) == (%{ errors: [%{ book_lent: %{ message: "Book not lent.", details: [] } }] } |> jsonise())
    end
  end

  describe "remove" do
    test "remove a book.", %{conn: conn} do
      Repo.insert! @book1
      assert Book.find(@book1.id)

      conn = delete(conn, "/api/books/#{@book1.id}")

      assert conn.status == 204
      refute Book.find(@book1.id)
    end

    test "remove an nonexistent book.", %{conn: conn} do
      book_id = 42

      conn = delete(conn, "/api/books/#{book_id}")

      assert json_response(conn, 400) == (%{ errors: [%{ book: %{ message: "Invalid book id.", details: [] } }] } |> jsonise())
    end

    test "remove a removed book.", %{conn: conn} do
      Repo.insert! @book1
      assert {:ok, _} = Book.remove(@book1.id)
      refute Book.find(@book1.id)

      conn = delete(conn, "/api/books/#{@book1.id}")

      assert json_response(conn, 400) == (%{ errors: [%{ book: %{ message: "Invalid book id.", details: [] } }] } |> jsonise())
    end
  end
end