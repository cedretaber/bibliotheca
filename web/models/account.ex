defmodule Bibliotheca.Account do
  use Bibliotheca.Web, :model

  schema "accounts" do
    field :name, :string
    field :deleted_at, :naive_datetime

    many_to_many :users, Bibliotheca.User, join_through: Bibliotheca.UserAccount

    timestamps()
  end

  alias Bibliotheca.Repo

  def changeset(struct, params, users \\ []) do
    changeset =
      struct
      |> cast(params, [:name, :deleted_at])
      |> validate_required([:name])
      |> unique_constraint(:name)

    if Enum.empty?(users),
      do: changeset,
      else: put_assoc(changeset, :users, users)
  end

  def all, do:
    Repo.all(from a in account_query(), preload: [:users])

  def create(param, users \\ []), do:
    Repo.insert(changeset %__MODULE__{}, param, users)

  def find(id), do:
    Repo.one(from a in account_query(), where: a.id == ^id, preload: [:users])

  def find_by_name(name), do:
    Repo.one(from a in account_query(), where: a.name == ^name, preload: [:users])

  def update(id, param) do
    case find(id) do
      nil     -> nil
      account -> Repo.update(changeset account, param)
    end
  end

  def delete(id), do:
    (account = find id) && Repo.update(changeset account, %{deleted_at: NaiveDateTime.utc_now})

  defp account_query, do:
    from a in __MODULE__, where: is_nil(a.deleted_at), order_by: [asc: a.id]
end