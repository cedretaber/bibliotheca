defmodule Bibliotheca.BookLentTest do
  use Bibliotheca.ModelCase

  alias Bibliotheca.{BookLent, BookRemoved, Book, User}

  @user %User{id: 1, email: "user1@example.com", password_digest: "xxxx", auth_code: "NORMAL"}
  @user2 %User{ @user | id: 2, email: "user2@example.com" }

  @book %Book{id: 1, title: "book"}

  @valid_attrs %{book_id: @book.id, user_id: @user.id}
  @invalid_attrs %{}

  describe "changeset" do
    test "changeset with valid attributes" do
      Repo.insert! @user
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
      Repo.insert! @user
      Repo.insert! @book

      refute BookLent.lending_user(@book.id)

      assert match? {:ok, _}, BookLent.lend(@user.id, @book.id)

      assert BookLent.lending_user(@book.id) == Repo.get(User, @user.id)
    end

    test "lending book which had been lent." do

      Repo.insert! @user
      Repo.insert! @user2
      Repo.insert! @book

      # 誰も借りてない
      refute BookLent.lending_user(@book.id)

      # user2が借りる
      assert match? {:ok, _}, BookLent.lend(@user2.id, @book.id)

      # user2が借りている
      assert BookLent.lending_user(@book.id) == Repo.get(User, @user2.id)

      # 返す
      assert match? {:ok, _}, BookLent.back(@user2.id, @book.id)

      # 誰も借りていない
      refute BookLent.lending_user(@book.id)

      # user1が借りる
      assert match? {:ok, _}, BookLent.lend(@user.id, @book.id)

      # user1が借りている
      assert BookLent.lending_user(@book.id) == Repo.get(User, @user.id)
    end

    test "lending book which is lent now." do
      Repo.insert! @user
      Repo.insert! @user2
      Repo.insert! @book

      # 誰も借りてない
      refute BookLent.lending_user(@book.id)

      # user2が借りる
      assert match? {:ok, _}, BookLent.lend(@user2.id, @book.id)

      # user2が借りている
      assert BookLent.lending_user(@book.id) == Repo.get(User, @user2.id)

      # user1が借りようとする
      {:error, changeset} = BookLent.lend(@user.id, @book.id)
      assert {:book, "The book is already lent."} in extract_errors(changeset)
    end

    test "lending nonexistent book." do
      Repo.insert! @user

      {:error, changeset} = BookLent.lend(@user.id, 42)
      assert {:book, "Invalid book id."} in extract_errors(changeset)
    end

    test "lending book which was removed." do
      Repo.insert! @user
      Repo.insert! @book

      Repo.insert! BookRemoved.changeset(%{book_id: @book.id})

      {:error, changeset} = BookLent.lend(@user.id, @book.id)
      assert {:book, "Invalid book id."} in extract_errors(changeset)
    end

    test "lending book by nonexistent user." do
      Repo.insert! @book

      {:error, changeset} = BookLent.lend(42, @book.id)
      assert {:user, "Invalid user id."} in extract_errors(changeset)
    end
  end

  describe "back" do
    test "back a lending book." do
      Repo.insert! @user
      Repo.insert! @book

      refute BookLent.lending_user(@book.id)

      assert match? {:ok, _}, BookLent.lend(@user.id, @book.id)

      assert BookLent.lending_user(@book.id) == Repo.get(User, @user.id)

      assert match? {:ok, _}, BookLent.back(@user.id, @book.id)

      refute BookLent.lending_user(@book.id)
    end

    test "back a book which is not lent." do
      Repo.insert! @user
      Repo.insert! @book

      refute BookLent.lending_user(@book.id)

      {:error, changeset} = BookLent.back(@user.id, @book.id)
      assert {:book_lent, "Book not lent."} in extract_errors(changeset)
    end

    test "back nonexistent book." do
      Repo.insert! @user

      {:error, changeset} = BookLent.back(@user.id, 42)
      assert {:book_lent, "Book not lent."} in extract_errors(changeset)
    end

    test "back a book by nonexistent user." do
      Repo.insert! @book

      {:error, changeset} = BookLent.back(42, @book.id)
      assert {:book_lent, "Book not lent."} in extract_errors(changeset)
    end
  end

  describe "lending_books" do
    test "user who has lent no book." do
      assert BookLent.lending_books(@user.id) == []
    end

    test "user who is lending some books." do
      Repo.insert! @user

      book1 = @book
      book2 = %Book{ book1 | id: 2, title: "book2" }
      book3 = %Book{ book1 | id: 3, title: "book3" }

      books = [book1, book2, book3]

      for book <- books do
        Repo.insert! book
        assert match? {:ok, _}, BookLent.lend(@user.id, book.id)
      end

      extract_id = fn books -> for book <- books, do: book.id end

      assert extract_id.(BookLent.lending_books @user.id) == extract_id.(books)
    end

    test "user who has lent and backed some books." do
      Repo.insert! @user

      book1 = @book
      book2 = %Book{ book1 | id: 2, title: "book2" }
      book3 = %Book{ book1 | id: 3, title: "book3" }

      for book <- [book1, book2, book3] do
        Repo.insert! book
        assert match? {:ok, _}, BookLent.lend(@user.id, book.id)
      end

      assert match? {:ok, _}, BookLent.back(@user.id, book2.id)

      extract_id = fn books -> for book <- books, do: book.id end

      assert extract_id.(BookLent.lending_books @user.id) == extract_id.([book1, book3])
    end
  end

  describe "lending_user" do
    test "book which nobody has lent." do
      Repo.insert! @book

      refute BookLent.lending_user(@book.id)
    end

    test "book which is lent." do
      Repo.insert! @user
      Repo.insert! @book

      assert match? {:ok, _}, BookLent.lend(@user.id, @book.id)

      assert BookLent.lending_user(@book.id).id == @user.id
    end

    test "book which has lent." do
      Repo.insert! @user
      Repo.insert! @book

      assert match? {:ok, _}, BookLent.lend(@user.id, @book.id)
      assert match? {:ok, _}, BookLent.back(@user.id, @book.id)

      refute BookLent.lending_user(@book.id)
    end

    test "book which was removed." do
      Repo.insert! @user
      Repo.insert! @book

      assert match? {:ok, _}, BookLent.lend(@user.id, @book.id)
      assert match? {:ok, _}, BookLent.back(@user.id, @book.id)

      Repo.insert! BookRemoved.changeset(%{book_id: @book.id})

      refute BookLent.lending_user(@book.id)
    end
  end

  describe "lentable_book" do
    test "book which nodoby has lent." do
      Repo.insert! @book

      assert BookLent.lentable_book(@book.id) == :ok
    end

    test "book which has been lent." do
      Repo.insert! @user
      Repo.insert! @book

      assert match? {:ok, _}, BookLent.lend(@user.id, @book.id)
      assert match? {:ok, _}, BookLent.back(@user.id, @book.id)

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

  describe "lentable_user" do
    test "valid user." do
      Repo.insert! @user

      assert BookLent.lentable_user(@user.id) == :ok
    end

    test "nonexistent user." do
      assert BookLent.lentable_user(42) == {:error, "Invalid user id."}
    end
  end
end
