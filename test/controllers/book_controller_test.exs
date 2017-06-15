defmodule Bibliotheca.BookControllerTest do
  use Bibliotheca.ConnCase, async: true

  alias Bibliotheca.{Repo, Book, BookLent, User}
  alias Bibliotheca.Api.BookView

  @user1 @user
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
        (BookView.render("index.json", %{ books: (for book <- [@book1, @book2, @book3], do: Repo.one(from b in Book, where: b.id == ^book.id, preload: [:authors], select: b)) }) |> jsonise())["books"]
    end

    test "search one book" , %{conn: conn} do
      for book <- [@book1, @book2, @book3], do: Repo.insert! book

      conn = get(conn, "/api/books/?q=book2")

      assert (json_response(conn, 200)["books"] |> Enum.sort_by(&(&1["id"]))) ==
             (BookView.render("index.json", %{ books: [Repo.one(from b in Book, where: b.id == ^@book2.id, preload: [:authors], select: b)] }) |> jsonise())["books"]
    end

    test "with query all books.", %{conn: conn} do
      for book <- [@book1, @book2, @book3], do: Repo.insert! book

      conn = get(conn, "/api/books/?q=book")

      assert (json_response(conn, 200)["books"] |> Enum.sort_by(&(&1["id"]))) ==
             (BookView.render("index.json", %{ books: (for book <- [@book1, @book2, @book3], do: Repo.one(from b in Book, where: b.id == ^book.id, preload: [:authors], select: b)) }) |> jsonise())["books"]
    end

    test "search some book.", %{conn: conn} do
      for book <- [@book1, @book2, @book3], do: Repo.insert! book

      conn = get(conn, "/api/books/?q=awesome")

      assert (json_response(conn, 200)["books"] |> Enum.sort_by(&(&1["id"]))) ==
             (BookView.render("index.json", %{ books: (for book <- [@book1, @book3], do: Repo.one(from b in Book, where: b.id == ^book.id, preload: [:authors], select: b)) }) |> jsonise())["books"]
    end
  end

  describe "lending/2" do
    test "when the user has lent no book.", %{conn: conn} do
      conn = get(conn, "/api/books/lending")

      assert json_response(conn, 200) == (BookView.render("index.json", %{books: []}) |> jsonise())
    end

    test "when the user is lending some books.", %{conn: conn} do
      book1 = @book1
      book2 = %{ book1 | id: 2, title: "book2" }
      book3 = %{ book1 | id: 3, title: "book3" }

      for book <- [book1, book2, book3] do
        Repo.insert! book
        assert match? {:ok, _}, BookLent.lend(@user1.id, book.id)
      end

      assert match? {:ok, _}, BookLent.back(@user1.id, book2.id)

      books = for book <- [book1, book3], do: Repo.get!(Book, book.id) |> Repo.preload(:authors)

      conn = get(conn, "/api/books/lending")
      assert json_response(conn, 200) == (BookView.render("index.json", %{books: books}) |> jsonise())
    end

    test "admin user can show books which another user is lending.", %{conn: conn} do
      Repo.insert! @user2

      book1 = @book1
      book2 = %{ book1 | id: 2, title: "book2" }
      book3 = %{ book1 | id: 3, title: "book3" }

      for book <- [book1, book2, book3] do
        Repo.insert! book
        assert match? {:ok, _}, BookLent.lend(@user2.id, book.id)
      end

      assert match? {:ok, _}, BookLent.back(@user2.id, book2.id)

      books = for book <- [book1, book3], do: Repo.get!(Book, book.id) |> Repo.preload(:authors)

      conn = get(conn, "/api/users/#{@user2.id}/lending")
      assert json_response(conn, 200) == (BookView.render("index.json", %{books: books}) |> jsonise())
    end

    test "normal user can't' show books which another user is lending.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @user3

      conn = conn
        |> login_user(@user3)
        |> get("/api/users/#{@user2.id}/lending")

      assert response(conn, 403) == "Forbidden"
    end
  end

  describe "show/2" do
    test "get a book.", %{conn: conn} do
      Repo.insert! @book1

      conn = get(conn, "/api/books/detail/#{@book1.id}")
      books = Repo.one(from b in Book, where: b.id == ^@book1.id, preload: [:authors], select: b)

      assert json_response(conn, 200) == (BookView.render("show.json", %{ book: books }) |> jsonise())
    end

    test "get a nonexistent book.", %{conn: conn} do
      conn = get(conn, "/api/books/detail/42")
      assert json_response(conn, 404) == %{ "error" => "Book Not Found" }
    end

    test "get a removed book.", %{conn: conn} do
      Repo.insert! @book1
      Book.remove(@book1.id)

      conn = get(conn, "/api/books/detail/#{@book1.id}")
      assert json_response(conn, 404) == %{ "error" => "Book Not Found" }
    end
  end

  describe "create/2" do
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

    test "there are no problem with a camelCase param.", %{conn: conn} do
      params =
        %{title: "book1",
          description: "An awesome book!",
          authors: ["author1", "author2", "author3"],
          publisher: "Pub co., ltd.",
          imageUrl: "http://example.com/sample.png",
          isbn: "123456789012X",
          pageCount: 334,
          publishedAt: "2010-04-01"}

      conn = post(conn, "/api/books", %{ book: params })

      book = Repo.get_by(Book, title: params[:title]) |> Repo.preload(:authors)

      for attr <- ~w(title description publisher imageUrl isbn pageCount)a, do:
        assert {:ok, params[attr]} == Map.fetch(book, String.to_atom Macro.underscore to_string attr)
      assert params[:authors] == (for author <- book.authors, do: author.name)
      assert ~D[2010-04-01] == book.published_at

      assert json_response(conn, 200) == (BookView.render("show.json", %{ book: book }) |> jsonise())
    end
  end

  describe "remove/2" do
    test "remove a book.", %{conn: conn} do
      Repo.insert! @book1
      assert Book.find(@book1.id)

      conn = delete(conn, "/api/books/remove/#{@book1.id}")

      assert conn.status == 204
      refute Book.find(@book1.id)
    end

    test "remove an nonexistent book.", %{conn: conn} do
      book_id = 42

      conn = delete(conn, "/api/books/remove/#{book_id}")

      assert json_response(conn, 400) == (%{ errors: [%{ book: %{ message: "Invalid book id.", details: [] } }] } |> jsonise())
    end

    test "remove a removed book.", %{conn: conn} do
      Repo.insert! @book1
      assert {:ok, _} = Book.remove(@book1.id)
      refute Book.find(@book1.id)

      conn = delete(conn, "/api/books/remove/#{@book1.id}")

      assert json_response(conn, 400) == (%{ errors: [%{ book: %{ message: "Invalid book id.", details: [] } }] } |> jsonise())
    end
  end
end