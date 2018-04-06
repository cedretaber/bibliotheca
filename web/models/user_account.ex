defmodule Bibliotheca.UserAccount do
  use Bibliotheca.Web, :model

  @primary_key false

  schema "user_accounts" do
    belongs_to(:account, Bibliotheca.Account, primary_key: true)
    belongs_to(:user, Bibliotheca.User, primary_key: true)

    timestamps(updated_at: false)
  end

  alias Bibliotheca.{Repo, Account, User}

  def changeset(param),
    do:
      %__MODULE__{}
      |> cast(param, [:account_id, :user_id])
      |> validate_required([:account_id, :user_id])
      |> validate_relation(
        param["account_id"] || param[:account_id],
        param["user_id"] || param[:user_id]
      )

  def own?(user_id, account_id),
    do: !!Repo.get_by(__MODULE__, account_id: account_id, user_id: user_id)

  def create(user_id, account_id),
    do: Repo.insert(changeset(%{account_id: account_id, user_id: user_id}))

  def delete(user_id, account_id) do
    case Repo.get_by(__MODULE__, account_id: account_id, user_id: user_id) do
      nil -> {:error, error_changeset(:relation, "Not associated.")}
      relation -> Repo.delete(relation)
    end
  end

  defp validate_relation(changeset, nil, _), do: changeset
  defp validate_relation(changeset, _, nil), do: changeset

  defp validate_relation(changeset, account_id, user_id) do
    error = fn key, msg -> add_error(changeset, key, msg) end

    with {:ok, _} <- find_account(account_id),
         {:ok, _} <- find_user(user_id),
         nil <- Repo.get_by(__MODULE__, account_id: account_id, user_id: user_id) do
      changeset
    else
      {:error, :account} -> error.(:account, "Invalid account id.")
      {:error, :user} -> error.(:user, "Invalid user id.")
      _ -> error.(:user_account, "Relation already exists.")
    end
  end

  defp find_account(account_id),
    do: if(account = Repo.get(Account, account_id), do: {:ok, account}, else: {:error, :account})

  defp find_user(user_id),
    do: if(user = Repo.get(User, user_id), do: {:ok, user}, else: {:error, :user})

  defp error_changeset(key, message),
    do: %__MODULE__{} |> cast(%{}, []) |> add_error(key, message)
end
