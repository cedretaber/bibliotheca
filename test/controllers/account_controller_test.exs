defmodule Bibliotheca.AccountControllerTest do
  use Bibliotheca.ConnCase, async: true

  alias Bibliotheca.{Repo, Book, BookLent, User}
  alias Bibliotheca.Api.AccountView

  describe "lend/2" do
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
      assert match?({:error, _}, BookLent.lentable_book(book_id))

      conn = conn
        |> login_user(@user2)
        |> get("/api/books/lend/#{book_id}")

      assert json_response(conn, 400) == (%{ errors: [%{ book: %{ message: "Invalid book id.", details: [] } }] } |> jsonise())
    end

    test "lent a book which is already lent by normal user.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @user3
      Repo.insert! @book1
      assert match? {:ok, _}, BookLent.lend(@user3.id, @book1.id)
      assert BookLent.lending_user(@book1.id).id == @user3.id

      conn = conn
        |> login_user(@user2)
        |> get("/api/books/lend/#{@book1.id}")

      assert json_response(conn, 400) == (%{ errors: [%{ book: %{ message: "The book is already lent.", details: [] } }] } |> jsonise())
    end

    test "an admin user make another user to lent a book.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @book1
      assert BookLent.lentable_book(@book1.id) == :ok

      conn = get(conn, "/api/users/#{@user2.id}/books/lend/#{@book1.id}")

      assert conn.status == 204
      assert BookLent.lending_user(@book1.id).id == @user2.id
    end

    test "a normal user can't' make another user to lend a book.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @user3
      Repo.insert! @book1
      assert BookLent.lentable_book(@book1.id) == :ok

      conn = conn
        |> login_user(@user2)
        |> get("/api/users/#{@user3.id}/books/lend/#{@book1.id}")

      assert response(conn, 403) == "Forbidden"
      refute BookLent.lending_user(@book1.id)
    end
  end

  describe "back/2" do
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
      assert match? {:ok, _}, BookLent.lend(@user3.id, @book1.id)
      assert BookLent.lending_user(@book1.id).id == @user3.id

      conn = conn
        |> login_user(@user2)
        |> delete("/api/books/back/#{@book1.id}")

      assert json_response(conn, 400) == (%{ errors: [%{ book_lent: %{ message: "Book not lent.", details: [] } }] } |> jsonise())
    end

    test "an admin user make another user to back a book.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @book1
      assert match? {:ok, _}, BookLent.lend(@user2.id, @book1.id)
      assert BookLent.lending_user(@book1.id).id == @user2.id

      conn = delete(conn, "/api/users/#{@user2.id}/books/back/#{@book1.id}")

      assert conn.status == 204
      refute BookLent.lending_user(@book1.id)
      assert BookLent.lentable_book(@book1.id) == :ok
    end

    test "a normal user can't' make another user to back a book.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @user3
      Repo.insert! @book1
      assert match? {:ok, _}, BookLent.lend(@user3.id, @book1.id)
      assert BookLent.lending_user(@book1.id).id == @user3.id

      conn = conn
        |> login_user(@user2)
        |> delete("/api/users/#{@user3.id}/books/back/#{@book1.id}")

      assert response(conn, 403) == "Forbidden"
      assert BookLent.lending_user(@book1.id).id == @user3.id
    end
  end
end