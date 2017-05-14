defmodule Bibliotheca.BookBackedTest do
  use Bibliotheca.ModelCase

  alias Bibliotheca.{Repo, Book, BookBacked, BookLent, User}

  @user %User{id: 1, email: "user1@example.com", password_digest: "xxxx", auth_code: "NORMAL"}
  @book %Book{id: 1, title: "book"}
  @book_lent %BookLent{id: 1, book_id: @book.id, user_id: @user.id}

  @valid_attrs %{book_id: @book.id, user_id: @user.id}
  @invalid_attrs %{}

  describe "changeset" do
    test "changeset with valid attributes" do
      Repo.insert @user
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
      Repo.insert @user
      Repo.insert @book
      Repo.insert @book_lent

      {:ok, book_backed} = BookBacked.back(@user.id, @book.id)
      assert book_backed.book_lent_id == @book_lent.id
    end

    test "back invalid book lending." do
      Repo.insert @user
      Repo.insert @book
      Repo.insert @book_lent

      {:error, changeset} = BookBacked.back(@user.id, 42)
      assert {:book_lent, "Book not lent."} in extract_errors(changeset)
    end

    test "back by invalid user." do
      Repo.insert @user
      Repo.insert @book
      Repo.insert @book_lent

      {:error, changeset} = BookBacked.back(42, @book.id)
      assert {:book_lent, "Book not lent."} in extract_errors(changeset)
    end
  end
end
