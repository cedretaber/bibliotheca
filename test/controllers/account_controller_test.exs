defmodule Bibliotheca.AccountControllerTest do
  use Bibliotheca.ConnCase, async: true

  alias Bibliotheca.{Repo, Account, Book, BookLent, User, UserAccount}

  @user2 %User{id: 2, email: "user2@example.com", password_digest: "password", auth_code: "NORMAL"}

  @account1 %Account{id: 1, name: "account1"}
  @account2 %Account{id: 2, name: "account2"}

  @book1 %Book{id: 1, title: "book1", description: "awesome book."}
  @book2 %Book{id: 2, title: "book2", description: "normal book."}
  @book3 %Book{id: 3, title: "book3", description: "awesome cool book."}

  describe "lend/2" do
    test "lent a book by normal user.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @account1
      assert match? {:ok, _}, UserAccount.create(@user2.id, @account1.id)

      Repo.insert! @book1
      assert BookLent.lentable_book(@book1.id) == :ok

      conn = conn
        |> login_user(@user2)
        |> get("/api/accounts/#{@account1.id}/books/#{@book1.id}")

      assert conn.status == 204
      assert BookLent.lending_account(@book1.id).id == @account1.id
    end

    test "lent an nonexistent book by normal user.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @account1
      assert match? {:ok, _}, UserAccount.create(@user2.id, @account1.id)

      book_id = 42
      assert match?({:error, _}, BookLent.lentable_book(book_id))

      conn = conn
        |> login_user(@user2)
        |> get("/api/accounts/#{@account1.id}/books/#{book_id}")

      assert json_response(conn, 400) == (%{ errors: [%{ book: %{ message: "Invalid book id.", details: [] } }] } |> jsonise())
    end

    test "lent a book which is already lent by normal user.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @account1
      Repo.insert! @account2
      assert match? {:ok, _}, UserAccount.create(@user2.id, @account1.id)

      Repo.insert! @book1
      assert match? {:ok, _}, BookLent.lend(@account2.id, @book1.id)
      assert BookLent.lending_account(@book1.id).id == @account2.id

      conn = conn
        |> login_user(@user2)
        |> get("/api/accounts/#{@account1.id}/books/#{@book1.id}")

      assert json_response(conn, 400) == (%{ errors: [%{ book: %{ message: "The book is already lent.", details: [] } }] } |> jsonise())
    end

    test "an admin user make non related user to lent a book.", %{conn: conn} do
      Repo.insert! @account1
      Repo.insert! @book1
      assert BookLent.lentable_book(@book1.id) == :ok

      conn = get(conn, "/api/accounts/#{@account1.id}/books/#{@book1.id}")

      assert conn.status == 204
      assert BookLent.lending_account(@book1.id).id == @account1.id
    end

    test "a normal user can't' make non related account to lend a book.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @account1
      Repo.insert! @book1
      assert BookLent.lentable_book(@book1.id) == :ok

      conn = conn
        |> login_user(@user2)
        |> get("/api/accounts/#{@account1.id}/books/#{@book1.id}")

      assert response(conn, 403) == "Forbidden"
      refute BookLent.lending_account(@book1.id)
    end
  end

  describe "back/2" do
    test "back a book lent by normal user.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @account1
      assert match? {:ok, _}, UserAccount.create(@user2.id, @account1.id)

      Repo.insert! @book1
      assert {:ok, _} = BookLent.lend(@account1.id, @book1.id)
      assert BookLent.lending_account(@book1.id).id == @account1.id

      conn = conn
        |> login_user(@user2)
        |> delete("/api/accounts/#{@account1.id}/books/#{@book1.id}")

      assert conn.status == 204
      refute BookLent.lending_account(@book1.id)
      assert BookLent.lentable_book(@book1.id) == :ok
    end

    test "back a book which is not lent.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @account1
      assert match? {:ok, _}, UserAccount.create(@user2.id, @account1.id)

      Repo.insert! @book1
      refute BookLent.lending_account(@book1.id)

      conn = conn
        |> login_user(@user2)
        |> delete("/api/accounts/#{@account1.id}/books/#{@book1.id}")

      assert json_response(conn, 400) ==
        (%{ errors: [%{ book_lent: %{ message: "Book not lent.", details: [] } }] } |> jsonise())
    end

    test "back a book which is lent by another account.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @account1
      Repo.insert! @account2
      assert match? {:ok, _}, UserAccount.create(@user2.id, @account1.id)

      Repo.insert! @book1
      assert match? {:ok, _}, BookLent.lend(@account2.id, @book1.id)
      assert BookLent.lending_account(@book1.id).id == @account2.id

      conn = conn
        |> login_user(@user2)
        |> delete("/api/accounts/#{@account1.id}/books/#{@book1.id}")

      assert json_response(conn, 400) ==
        (%{ errors: [%{ book_lent: %{ message: "Book not lent.", details: [] } }] } |> jsonise())
    end

    test "an admin user make non related account to back a book.", %{conn: conn} do
      Repo.insert! @account1
      Repo.insert! @book1
      assert match? {:ok, _}, BookLent.lend(@account1.id, @book1.id)
      assert BookLent.lending_account(@book1.id).id == @account1.id

      conn = delete(conn, "/api/accounts/#{@account1.id}/books/#{@book1.id}")

      assert conn.status == 204
      refute BookLent.lending_account(@book1.id)
      assert BookLent.lentable_book(@book1.id) == :ok
    end

    test "a normal user can't' make non related account to back a book.", %{conn: conn} do
      Repo.insert! @user2
      Repo.insert! @account1
      Repo.insert! @book1
      assert match? {:ok, _}, BookLent.lend(@account1.id, @book1.id)
      assert BookLent.lending_account(@book1.id).id == @account1.id

      conn = conn
        |> login_user(@user2)
        |> delete("/api/accounts/#{@account1.id}/books/#{@book1.id}")

      assert response(conn, 403) == "Forbidden"
      assert BookLent.lending_account(@book1.id).id == @account1.id
    end
  end
end