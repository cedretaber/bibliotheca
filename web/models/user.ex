defmodule Bibliotheca.User do
  use Bibliotheca.Web, :model

  schema "users" do
    field(:email, :string)
    field(:password_digest, :string)
    field(:auth_code, :string)

    many_to_many(:accounts, Bibliotheca.Account, join_through: Bibliotheca.UserAccount)

    timestamps()
  end

  alias Bibliotheca.Auth.HMAC
  alias Bibliotheca.{Repo, User}

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, %{email: _} = params),
    do:
      struct
      |> cast(params, [:email])
      |> validate_required([:email])
      |> unique_constraint(:email)

  def changeset(struct, %{password_digest: _} = params),
    do:
      struct
      |> cast(params, [:password_digest])
      |> validate_required([:password_digest])

  def changeset(struct, params),
    do:
      struct
      |> cast(params, [:email, :password_digest, :auth_code])
      |> validate_required([:email, :password_digest, :auth_code])
      |> unique_constraint(:email)

  def all, do: Repo.all(user_query())

  def create(params), do: Repo.insert(changeset(%User{}, hash_password(params)))

  def find(id), do: Repo.one(from(u in user_query(), where: u.id == ^id))

  def find_by_email(email), do: Repo.one(from(u in user_query(), where: u.email == ^email))

  def update(id, params),
    do: (user = find(id)) && Repo.update(changeset(user, hash_password(params)))

  def update_email(id, email),
    do: (user = find(id)) && Repo.update(changeset(user, %{email: email}))

  def update_password(id, password),
    do:
      (user = find(id)) &&
        Repo.update(changeset(user, intern_password(hash_password(%{"password" => password}))))

  def delete(id) do
    with user when not is_nil(user) <- find(id),
         {:ok, _} = ret <- Repo.delete(user) do
      ret
    else
      error -> error
    end
  end

  defp user_query, do: from(u in __MODULE__, order_by: [asc: u.id])

  defp hash_password(params) do
    password_digest =
      case params["password"] do
        password when is_nil(password) or password == "" ->
          nil

        password ->
          HMAC.hexdigest(password)
      end

    put_in(params["password_digest"], password_digest)
  end

  defp intern_password(param), do: %{password_digest: param["password_digest"]}
end
