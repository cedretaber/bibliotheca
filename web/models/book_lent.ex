defmodule Bibliotheca.BookLent do
  use Bibliotheca.Web, :model

  schema "books_lent" do
    belongs_to(:book, Bibliotheca.Book)
    belongs_to(:account, Bibliotheca.Account)

    timestamps(updated_at: false)
  end

  alias Bibliotheca.{Repo, Account, Book, BookBacked, BookRemoved, BookLent}

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(params \\ %{}) do
    %BookLent{}
    |> cast(params, [:book_id, :account_id])
    |> validate_required([:book_id, :account_id])
    |> validate_change(:book_id, &validate/2)
    |> assoc_constraint(:book)
    |> validate_change(:account_id, &validate/2)
    |> assoc_constraint(:account)
  end

  def lend(account_id, book_id),
    do: Repo.insert(changeset(%{account_id: account_id, book_id: book_id}))

  def back(account_id, book_id), do: BookBacked.back(account_id, book_id)

  def lending_books(account_id),
    do:
      Repo.all(
        from(
          b in Book,
          inner_join: bl in BookLent,
          on: b.id == bl.book_id,
          inner_join: a in Account,
          on: bl.account_id == a.id,
          left_join: bb in BookBacked,
          on: bl.id == bb.book_lent_id,
          left_join: br in BookRemoved,
          on: b.id == br.book_id,
          where: a.id == ^account_id and is_nil(bb.book_lent_id) and is_nil(br.book_id),
          order_by: [asc: b.id],
          preload: [:authors],
          select: b
        )
      )

  def lending_account(book_id),
    do:
      Repo.one(
        from(
          a in Account,
          inner_join: bl in BookLent,
          on: a.id == bl.account_id,
          inner_join: b in Book,
          on: bl.book_id == b.id,
          left_join: bb in BookBacked,
          on: bl.id == bb.book_lent_id,
          left_join: br in BookRemoved,
          on: b.id == br.book_id,
          where: b.id == ^book_id and is_nil(bb.book_lent_id) and is_nil(br.book_id),
          select: a
        )
      )

  def lentable_book(book_id) do
    query =
      from(
        bl in __MODULE__,
        left_join: bb in BookBacked,
        on: bl.id == bb.book_lent_id,
        where: bl.book_id == ^book_id and is_nil(bb.book_lent_id),
        select: bl.id
      )

    with book when not is_nil(book) <- Book.find(book_id),
         nil <- Repo.one(query) do
      :ok
    else
      nil -> {:error, "Invalid book id."}
      _ -> {:error, "The book is already lent."}
    end
  end

  def lentable_account(account_id) do
    query = from(a in Account, where: a.id == ^account_id)

    case Repo.one(query) do
      nil -> {:error, "Invalid account id."}
      _ -> :ok
    end
  end

  defp validate(:book_id, book_id) do
    case lentable_book(book_id) do
      :ok -> []
      {:error, msg} -> [book: msg]
    end
  end

  defp validate(:account_id, account_id) do
    case lentable_account(account_id) do
      :ok -> []
      {:error, msg} -> [account: msg]
    end
  end
end
