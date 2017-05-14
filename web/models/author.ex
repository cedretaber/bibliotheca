defmodule Bibliotheca.Author do
  use Bibliotheca.Web, :model

  alias Bibliotheca.{Repo, Author}

  schema "authors" do
    field :name, :string

    many_to_many :books, Bibliotheca.Book, join_through: "book_authors"

    timestamps updated_at: false
  end

  @fields [:name]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required([:name])
  end

  def find_or_create name do
    case Repo.get_by(__MODULE__, name: name) do
      nil ->
        Repo.insert changeset(%Author{}, %{ name: name })
      author ->
        {:ok, author}
    end
  end
end