defmodule Bibliotheca.BookLentTest do
  use Bibliotheca.ModelCase

  alias Bibliotheca.{Account, Book, BookLent, BookRemoved}

  @account %Account{id: 1, name: "account1"}
  @account2 %Account{@account | id: 2, name: "account2"}

  @book %Book{id: 1, title: "book"}

  @valid_attrs %{book_id: @book.id, account_id: @account.id}
  @invalid_attrs %{}

  describe "changeset" do
    test "changeset with valid attributes" do
      Repo.insert! @account
      Repo.insert! @book

      changeset = BookLent.changeset(@valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = BookLent.changeset(@invalid_attrs)
      refute changeset.valid?
    end
  end

  describe "lend" do
    test "lending book which nobody has lent." do
      Repo.insert! @account
      Repo.insert! @book

      refute BookLent.lending_account(@account.id)

      assert match? {:ok, _}, BookLent.lend(@account.id, @book.id)

      assert BookLent.lending_account(@book.id) == Repo.get(Account, @account.id)
    end

    test "lending book which had been lent." do

      Repo.insert! @account
      Repo.insert! @account2
      Repo.insert! @book

      # 誰も借りてない
      refute BookLent.lending_account(@book.id)

      # account2が借りる
      assert match? {:ok, _}, BookLent.lend(@account2.id, @book.id)

      # account2が借りている
      assert BookLent.lending_account(@book.id) == Repo.get(Account, @account2.id)

      # 返す
      assert match? {:ok, _}, BookLent.back(@account2.id, @book.id)

      # 誰も借りていない
      refute BookLent.lending_account(@book.id)

      # account1が借りる
      assert match? {:ok, _}, BookLent.lend(@account.id, @book.id)

      # account1が借りている
      assert BookLent.lending_account(@book.id) == Repo.get(Account, @account.id)
    end

    test "lending book which is lent now." do
      Repo.insert! @account
      Repo.insert! @account2
      Repo.insert! @book

      # 誰も借りてない
      refute BookLent.lending_account(@book.id)

      # account2が借りる
      assert match? {:ok, _}, BookLent.lend(@account2.id, @book.id)

      # account2が借りている
      assert BookLent.lending_account(@book.id) == Repo.get(Account, @account2.id)

      # account1が借りようとする
      {:error, changeset} = BookLent.lend(@account.id, @book.id)
      assert {:book, "The book is already lent."} in extract_errors(changeset)
    end

    test "lending nonexistent book." do
      Repo.insert! @account

      {:error, changeset} = BookLent.lend(@account.id, 42)
      assert {:book, "Invalid book id."} in extract_errors(changeset)
    end

    test "lending book which was removed." do
      Repo.insert! @account
      Repo.insert! @book

      Repo.insert! BookRemoved.changeset(%{book_id: @book.id})

      {:error, changeset} = BookLent.lend(@account.id, @book.id)
      assert {:book, "Invalid book id."} in extract_errors(changeset)
    end

    test "lending book by nonexistent account." do
      Repo.insert! @book

      {:error, changeset} = BookLent.lend(42, @book.id)
      assert {:account, "Invalid account id."} in extract_errors(changeset)
    end
  end

  describe "back" do
    test "back a lending book." do
      Repo.insert! @account
      Repo.insert! @book

      refute BookLent.lending_account(@book.id)

      assert match? {:ok, _}, BookLent.lend(@account.id, @book.id)

      assert BookLent.lending_account(@book.id) == Repo.get(Account, @account.id)

      assert match? {:ok, _}, BookLent.back(@account.id, @book.id)

      refute BookLent.lending_account(@book.id)
    end

    test "back a book which is not lent." do
      Repo.insert! @account
      Repo.insert! @book

      refute BookLent.lending_account(@book.id)

      {:error, changeset} = BookLent.back(@account.id, @book.id)
      assert {:book_lent, "Book not lent."} in extract_errors(changeset)
    end

    test "back nonexistent book." do
      Repo.insert! @account

      {:error, changeset} = BookLent.back(@account.id, 42)
      assert {:book_lent, "Book not lent."} in extract_errors(changeset)
    end

    test "back a book by nonexistent account." do
      Repo.insert! @book

      {:error, changeset} = BookLent.back(42, @book.id)
      assert {:book_lent, "Book not lent."} in extract_errors(changeset)
    end
  end

  describe "lending_books" do
    test "account who has lent no book." do
      assert BookLent.lending_books(@account.id) == []
    end

    test "account who is lending some books." do
      Repo.insert! @account

      book1 = @book
      book2 = %Book{ book1 | id: 2, title: "book2" }
      book3 = %Book{ book1 | id: 3, title: "book3" }

      books = [book1, book2, book3]

      for book <- books do
        Repo.insert! book
        assert match? {:ok, _}, BookLent.lend(@account.id, book.id)
      end

      extract_id = fn books -> for book <- books, do: book.id end

      assert extract_id.(BookLent.lending_books @account.id) == extract_id.(books)
    end

    test "account who has lent and backed some books." do
      Repo.insert! @account

      book1 = @book
      book2 = %Book{ book1 | id: 2, title: "book2" }
      book3 = %Book{ book1 | id: 3, title: "book3" }

      for book <- [book1, book2, book3] do
        Repo.insert! book
        assert match? {:ok, _}, BookLent.lend(@account.id, book.id)
      end

      assert match? {:ok, _}, BookLent.back(@account.id, book2.id)

      extract_id = fn books -> for book <- books, do: book.id end

      assert extract_id.(BookLent.lending_books @account.id) == extract_id.([book1, book3])
    end
  end

  describe "lending_account" do
    test "book which nobody has lent." do
      Repo.insert! @book

      refute BookLent.lending_account(@book.id)
    end

    test "book which is lent." do
      Repo.insert! @account
      Repo.insert! @book

      assert match? {:ok, _}, BookLent.lend(@account.id, @book.id)

      assert BookLent.lending_account(@book.id).id == @account.id
    end

    test "book which has lent." do
      Repo.insert! @account
      Repo.insert! @book

      assert match? {:ok, _}, BookLent.lend(@account.id, @book.id)
      assert match? {:ok, _}, BookLent.back(@account.id, @book.id)

      refute BookLent.lending_account(@book.id)
    end

    test "book which was removed." do
      Repo.insert! @account
      Repo.insert! @book

      assert match? {:ok, _}, BookLent.lend(@account.id, @book.id)
      assert match? {:ok, _}, BookLent.back(@account.id, @book.id)

      Repo.insert! BookRemoved.changeset(%{book_id: @book.id})

      refute BookLent.lending_account(@book.id)
    end
  end

  describe "lentable_book" do
    test "book which nodoby has lent." do
      Repo.insert! @book

      assert BookLent.lentable_book(@book.id) == :ok
    end

    test "book which has been lent." do
      Repo.insert! @account
      Repo.insert! @book

      assert match? {:ok, _}, BookLent.lend(@account.id, @book.id)
      assert match? {:ok, _}, BookLent.back(@account.id, @book.id)

      assert BookLent.lentable_book(@book.id) == :ok
    end

    test "nonexistent book." do
      assert BookLent.lentable_book(42) == {:error, "Invalid book id."}
    end

    test "removed book." do
      Repo.insert! @book
      Repo.insert! BookRemoved.changeset(%{book_id: @book.id})

      assert BookLent.lentable_book(42) == {:error, "Invalid book id."}
    end
  end

  describe "lentable_account" do
    test "valid account." do
      Repo.insert! @account

      assert BookLent.lentable_account(@account.id) == :ok
    end

    test "nonexistent account." do
      assert BookLent.lentable_account(42) == {:error, "Invalid account id."}
    end
  end
end
