defmodule Bibliotheca.BookRemovedTest do
  use Bibliotheca.ModelCase

  alias Bibliotheca.{Repo, Book, BookRemoved}

  @book %Book{id: 1, title: "book"}

  @valid_attrs %{book_id: @book.id}
  @invalid_attrs %{}

  describe "changeset" do
    test "changeset with valid attributes" do
      Repo.insert @book

      changeset = BookRemoved.changeset(@valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = BookRemoved.changeset(@invalid_attrs)
      refute changeset.valid?
    end
  end
end
