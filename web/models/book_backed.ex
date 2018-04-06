defmodule Bibliotheca.BookBacked do
  use Bibliotheca.Web, :model

  @primary_key false

  schema "books_backed" do
    belongs_to(:book_lent, Bibliotheca.BookLent, primary_key: true)

    timestamps(updated_at: false)
  end

  alias Bibliotheca.{Repo, BookBacked, BookLent}

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(params \\ %{}) do
    %BookBacked{}
    |> cast(params, [])
    |> validate_book_lent(params)
  end

  def back(account_id, book_id),
    do: Repo.insert(changeset(%{account_id: account_id, book_id: book_id}))

  defp validate_book_lent(changeset, params) do
    with {:ok, book_id} <- fetch(params, :book_id),
         {:ok, account_id} <- fetch(params, :account_id),
         book_lent when not is_nil(book_lent) <- find_book_lent(account_id, book_id) do
      put_assoc(changeset, :book_lent, book_lent)
    else
      {:error, :book_id} -> add_error(changeset, :book, "Missing book id.")
      {:error, :account_id} -> add_error(changeset, :account, "Missing account id.")
      nil -> add_error(changeset, :book_lent, "Book not lent.")
    end
  end

  defp fetch(map, key) do
    if ret = get_in(map, [key]) do
      {:ok, ret}
    else
      {:error, key}
    end
  end

  defp find_book_lent(account_id, book_id),
    do:
      Repo.one(
        from(
          bl in BookLent,
          left_join: bb in BookBacked,
          on: bl.id == bb.book_lent_id,
          where:
            bl.book_id == ^book_id and bl.account_id == ^account_id and is_nil(bb.book_lent_id)
        )
      )
end
