defmodule Bibliotheca.BookLent do
  use Bibliotheca.Web, :model

  schema "books_lent" do
    belongs_to :book, Bibliotheca.Book
    belongs_to :user, Bibliotheca.User

    timestamps updated_at: false
  end

  alias Bibliotheca.{Repo, Book, BookBacked, BookLent, User}

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(params \\ %{}) do
    %BookLent{}
    |> cast(params, [:book_id, :user_id])
    |> validate_required([:book_id, :user_id])
    |> validate_change(:book_id, &validate/2)
    |> assoc_constraint(:book)
    |> validate_change(:user_id, &validate/2)
    |> assoc_constraint(:user)
  end

  def lend(user_id, book_id), do:
    Repo.insert(changeset(%{user_id: user_id, book_id: book_id}))

  def back(user_id, book_id), do:
    BookBacked.back(user_id, book_id)

  def lending_books(user_id), do:
    Repo.all(
      from b in Book,
        inner_join: bl in BookLent, on: b.id == bl.book_id,
        inner_join: u in User, on: bl.user_id == u.id,
        left_join: bb in BookBacked, on: bl.id == bb.book_lent_id,
        where: u.id == ^user_id and is_nil(bb.id),
        order_by: [asc: b.id],
        preload: [:authors],
        select: b
    )

  def lending_user(book_id), do:
    Repo.one(
      from u in User,
        inner_join: bl in BookLent, on: u.id == bl.user_id,
        inner_join: b in Book, on: bl.book_id == b.id,
        left_join: bb in BookBacked, on: bl.id == bb.book_lent_id,
        where: b.id == ^book_id and is_nil(bb.id),
        select: u
    )

  def lentable_book(book_id) do
    query =
      from bl in __MODULE__,
        left_join: bb in BookBacked, on: bl.id == bb.book_lent_id,
        where: bl.book_id == ^book_id and is_nil(bb.id),
        select: bl.id
    with book when not is_nil(book) <- Book.find(book_id),
         nil <- Repo.one(query)
    do
      :ok
    else
      nil -> {:error, "Invalid book id."}
      _ -> {:error, "The book is already lent."}
    end
  end

  def lentable_user(user_id) do
    query =
      from u in User,
        where: u.id == ^user_id
    case Repo.one(query) do
      nil -> {:error, "Invalid user id."}
      _ -> :ok
    end
  end

  defp validate(:book_id, book_id) do
    case lentable_book(book_id) do
      :ok -> []
      {:error, msg} -> [book: msg]
    end
  end

  defp validate(:user_id, user_id) do
    case lentable_user(user_id) do
      :ok -> []
      {:error, msg} -> [user: msg]
    end
  end
end
