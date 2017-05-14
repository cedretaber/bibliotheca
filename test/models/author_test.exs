defmodule Bibliotheca.AuthorTest do
  use Bibliotheca.ModelCase

  alias Bibliotheca.{Repo, Author}

  @valid_attes %{name: "name"}
  @invalid_attrs %{}

  describe "changeset" do
    test "changeset with valid attributes" do
      changeset = Author.changeset(%Author{}, @valid_attes)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Author.changeset(%Author{}, @invalid_attrs)
      refute changeset.valid?
    end
  end

  describe "find_or_create" do
    test "can find and return current." do
      author = %Author{id: 1, name: "author"}
      Repo.insert! author

      {:ok, res} = Author.find_or_create(author.name)
      assert res.id == author.id
      assert res.name == author.name
    end

    test "can't find, create new author and return it." do
      name = "new author"
      assert Repo.get_by(Author, name: name) == nil

      {:ok, res} = Author.find_or_create(name)
      assert res.name == name
    end
  end
end