defmodule Bibliotheca.BookBackedTest do
  use Bibliotheca.ModelCase

  alias Bibliotheca.{Repo, Account, Book, BookBacked, BookLent}

  @account %Account{id: 1, name: "account"}
  @book %Book{id: 1, title: "book"}
  @book_lent %BookLent{id: 1, book_id: @book.id, account_id: @account.id}

  @valid_attrs %{book_id: @book.id, account_id: @account.id}
  @invalid_attrs %{}

  describe "changeset" do
    test "changeset with valid attributes" do
      Repo.insert @account
      Repo.insert @book
      Repo.insert @book_lent

      changeset = BookBacked.changeset(@valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = BookBacked.changeset(@invalid_attrs)
      refute changeset.valid?
    end
  end

  describe "back" do
    test "back valid book lending." do
      Repo.insert @account
      Repo.insert @book
      Repo.insert @book_lent

      {:ok, book_backed} = BookBacked.back(@account.id, @book.id)
      assert book_backed.book_lent_id == @book_lent.id
    end

    test "back invalid book lending." do
      Repo.insert @account
      Repo.insert @book
      Repo.insert @book_lent

      {:error, changeset} = BookBacked.back(@account.id, 42)
      assert {:book_lent, "Book not lent."} in extract_errors(changeset)
    end

    test "back by invalid account." do
      Repo.insert @account
      Repo.insert @book
      Repo.insert @book_lent

      {:error, changeset} = BookBacked.back(42, @book.id)
      assert {:book_lent, "Book not lent."} in extract_errors(changeset)
    end
  end
end
