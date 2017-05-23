defmodule Bibliotheca.BookTest do
  use Bibliotheca.ModelCase

  alias Bibliotheca.{Repo, Author, Book, BookLent, BookRemoved, User}

  @valid_attrs %{title: "title",
                 authors: ["someone", "another one"],
                 description: "lorem ipsum...",
                 publisher: "some content",
                 image_url: "http://example.com/sample.png",
                 isbn: "123456789123X",
                 page_coung: 399,
                 published_at: ~D[2016-04-01]}
  @invalid_attrs %{}

  describe "changeset" do
    test "changeset with valid attributes" do
      changeset = Book.changeset(@valid_attrs)
      assert changeset.valid?
    end

    test "changeset with minimal valid attributes" do
      changeset = Book.changeset(%{ title: "title" })
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Book.changeset(@invalid_attrs)
      refute changeset.valid?
    end
  end

  describe "all" do
    test "get all books" do
      book1 = %Book{ id: 1, title: "book1" }
      book2 = %Book{ id: 2, title: "book1" }
      book3 = %Book{ id: 3, title: "book1" }
      book4 = %Book{ id: 4, title: "book4" }

      books = [book1, book2, book3, book4]
      books |> Enum.each(fn book -> Repo.insert(book) end)

      Repo.insert! %BookRemoved{ book_id: book3.id }

      Book.all()
      |> Enum.zip([book1, book2, book4])
      |> Enum.each(fn {ret, exp} ->
        assert ret.id == exp.id
        assert ret.title == exp.title
      end)
    end
  end

  describe "create" do
    test "create new book master" do
      title = "title"
      valid_param = %{"title" => title,
                      "authors" => ["author1", "author2", "author3"],
                      "description" => "rolem ipsum...",
                      "publisher" => "hoge.co.,ltd.",
                      "image_url" => "http://example.com/sample.png",
                      "isbn" => "123456789123X",
                      "page_count" => 334,
                      "published_at" => ~D[2000-04-01]}

      Repo.insert(%Author{name: "author1"})
      Repo.insert(%Author{name: "author2"})

      Book.create(valid_param)

      book =
        Book
        |> Repo.get_by(title: title)
        |> Repo.preload(:authors)

      attrs = ~w(title authors description piblisher image_url isbn page_count published_at)a
      Enum.each attrs, fn
        attr when attr != :authors ->
          assert Map.get(book, attr) == valid_param[Atom.to_string(attr)]
        attr ->
          authors =
            Map.get(book, attr)
            |> Enum.map(&(&1.name))
          assert authors == valid_param[Atom.to_string(attr)]
      end

      assert (Repo.all(Author) |> Enum.count) == 3
    end
  end

  describe "find" do
    test "find book by id" do
      book = %Book{ id: 1, title: "book" }
      Repo.insert! book

      assert Book.find(book.id).title == book.title
    end
  end

  describe "search" do
    test "search correct books" do
      author1 = %Author{ id: 1, name: "author1" }
      author2 = %Author{ id: 2, name: "author2" }
      author3 = %Author{ id: 3, name: "author3" }

      Enum.each [author1, author2, author3], fn author -> Repo.insert! author end

      book1 = %{"title" => "book1"}
      book2 = %{"title" => "book2",
                "authors" => [author1.name],
                "description" => "description number 2.",
                "isbn" => "1234567890123"}
      book3 = %{"title" => "book3",
                "authors" => [author2.name],
                "description" => "description number 3."}
      book4 = %{"title" => "book4",
                "authors" => [author1.name, author3.name],
                "isbn" => "999999999999X"}

      Enum.each [book1, book2, book3, book4], fn book -> Book.create book end

      book = fn id -> Book |> Repo.get_by(title: "book#{id}") |> Repo.preload(:authors) end

      assert Book.search("book1") == [book.(1)]
      assert Book.search("book") == [book.(1), book.(2), book.(3), book.(4)]
      assert Book.search("author1") == [book.(2), book.(4)]
      assert Book.search("number") == [book.(2), book.(3)]
      assert Book.search("number 3") == [book.(3)]
      assert Book.search("1234567890") == [book.(2)]
    end
  end

  describe "remove" do
    test "remove an existent book." do
      book = %Book{id: 1, title: "book"}
      Repo.insert! book

      assert BookRemoved.removed_book?(book.id) == false

      {:ok, _} = Book.remove(book.id)

      assert BookRemoved.removed_book?(book.id) == true
    end

    test "remove a removed book." do
      book = %Book{id: 1, title: "book"}
      Repo.insert! book
      {:ok, _} = Book.remove(book.id)

      {:error, changeset} = Book.remove(book.id)

      assert {:book, "Invalid book id."} in extract_errors(changeset)
    end

    test "remove a nonexistent book." do
      {:error, changeset} = Book.remove(42)
      assert {:book, "Invalid book id."} in extract_errors(changeset)
    end

    test "remove a book which was lent." do
      book = %Book{id: 1, title: "book"}
      Repo.insert! book

      user = %User{id: 1, email: "user@example.com", password_digest: "password", auth_code: "NORMAL"}
      Repo.insert! user

      {:ok, _} = BookLent.lend(user.id, book.id)

      {:error, changeset} = Book.remove(book.id)

      assert {:book, "The Book is still lent."} in extract_errors(changeset)
    end
  end
end
