defmodule Bibliotheca.Book do
  use Bibliotheca.Web, :model

  alias Bibliotheca.{Repo, Book, BookRemoved, Author}

  schema "books" do
    field :title, :string
    field :description, :string
    field :publisher, :string
    field :image_url, :string
    field :isbn, :string
    field :page_count, :integer
    field :published_at, :date

    many_to_many :authors, Bibliotheca.Author, join_through: "book_authors"

    timestamps updated_at: false
  end

  @fields ~w(title description publisher image_url isbn page_count published_at)a

  @doc """
  Builds a changeset based on `params`.
  """
  def changeset(params \\ %{}) do
    %Book{}
    |> cast(params, @fields)
    |> validate_required([:title])
    |> put_assoc(:authors, cast_authors(params["authors"] || params[:authors] || []))
  end

  def all, do:
    Repo.all(present_books_query())

  def create(params), do:
    Repo.insert(changeset(params))

  def find(id), do:
    Repo.one(
      from b in present_books_query(),
        where: b.id == ^id
    )

  def search keyword do
    k = "%#{keyword}%"
    q = from b in present_books_query(),
      left_join: ba in "book_authors", on: b.id == ba.book_id,
      left_join: a in Author, on: a.id == ba.author_id,
      where: like(a.name, ^k)
        or like(b.title, ^k)
        or like(b.description, ^k)
        or like(b.publisher, ^k)
        or like(b.isbn, ^k),
      distinct: b.id,
      preload: :authors,
      order_by: [asc: b.id]

    Repo.all(q)
  end

  def remove(book_id), do:
    Repo.insert(BookRemoved.changeset(%{book_id: book_id}))

  defp present_books_query, do:
    from b in __MODULE__,
      left_join: br in BookRemoved, on: b.id == br.book_id,
      where: is_nil(br.book_id),
      order_by: [asc: b.id],
      preload: [:authors],
      select: b

  defp cast_authors(author_names), do:
    author_names
    |> Enum.map(fn name ->
      case Author.find_or_create(name) do
        {:ok, author} -> author
        _ -> nil
      end
    end)
    |> Enum.reject(&(is_nil(&1)))
end
