defmodule Bibliotheca.Api.AccountController do
  use Bibliotheca.Web, :controller

  import Bibliotheca.Helpers.ErrorExtractor
  import Bibliotheca.Plugs.Authentication, only: [current_user: 1]
  import Bibliotheca.Plugs.CaseConverter, only: [conv_case: 2]

  alias Bibliotheca.{Account, BookLent, UserAccount}

  @account_not_found "Account Not Found"

  plug :scrub_params, "account" when action in [:create, :update]
  plug :conv_case when action in [:create, :update]
  plug :auth_user_account when action in [:lend, :back]

  def index(conn, _param), do: render(conn, :index, accounts: Account.all())

  def create(conn, %{"account" => account_params}),
    do: show_account(conn, Account.create(account_params))

  def show(conn, %{"id" => id}) do
    show_account(
      conn,
      case Account.find(id) do
        nil -> nil
        account -> {:ok, account}
      end
    )
  end

  def update(conn, %{"id" => id, "account" => account_params}),
    do: show_account(conn, Account.update(id, account_params))

  def delete(conn, %{"id" => id}), do: resp_no_content(conn, Account.delete(id))

  def lend(conn, %{"id" => id, "book_id" => book_id}),
    do: resp_no_content(conn, BookLent.lend(id, book_id))

  def back(conn, %{"id" => id, "book_id" => book_id}),
    do: resp_no_content(conn, BookLent.back(id, book_id))

  defp show_account(conn, ret_param) do
    case ret_param do
      {:ok, account} -> render(conn, :show, account: account)
      {:error, changeset} -> client_error(conn, changeset)
      nil -> account_not_found(conn)
    end
  end

  defp resp_no_content(conn, ret_param) do
    case ret_param do
      {:ok, _} -> send_resp(conn, 204, "")
      {:error, changeset} -> client_error(conn, changeset)
      nil -> account_not_found(conn)
    end
  end

  defp client_error(conn, changeset),
    do:
      conn
      |> put_status(400)
      |> json(%{errors: extract_errors(changeset)})

  defp account_not_found(conn) do
    conn
    |> put_status(:not_found)
    |> json(%{error: @account_not_found})
  end

  defp auth_user_account(conn, _),
    do:
      if(
        check_user_account(current_user(conn), conn.params["id"]),
        do: conn,
        else: conn |> send_resp(403, "Forbidden") |> halt
      )

  defp check_user_account(nil, _), do: false

  defp check_user_account(user, account_id),
    do: user.auth_code == "ADMIN" || UserAccount.own?(user.id, account_id)
end
