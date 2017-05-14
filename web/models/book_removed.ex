defmodule Bibliotheca.BookRemoved do
  use Bibliotheca.Web, :model

  schema "books_removed" do
    belongs_to :book, Bibliotheca.Book

    timestamps updated_at: false
  end

  alias Bibliotheca.{Repo, Book, BookBacked, BookLent, BookRemoved}

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(params \\ %{}) do
    %BookRemoved{}
    |> cast(params, [:book_id])
    |> validate_required([:book_id])
    |> validate_change(:book_id, &validate/2)
    |> assoc_constraint(:book)
  end

  def removed_book?(book_id) do
    query =
      from b in Book,
        left_join: br in BookRemoved, on: b.id == br.book_id,
        where: b.id == ^book_id,
        select: {b, br}

    case Repo.one(query) do
      nil -> {:error, "No such book."}
      {_, nil} -> false
      _ -> true
    end
  end

  defp validate(:book_id, book_id) do
    query =
      from b in Book,
        inner_join: bl in BookLent, on: b.id == bl.book_id,
        left_join: bb in BookBacked, on: bl.id == bb.book_lent_id,
        where: is_nil(bb.id)
    with book when not is_nil(book) <- Repo.get(Book, book_id),
         nil <- Repo.one(query)
    do
      []
    else
      nil -> [book: "Invalid book id."]
      _ -> [book: "The Book is still lent."]
    end
  end
end
