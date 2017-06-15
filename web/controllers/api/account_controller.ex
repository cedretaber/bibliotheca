defmodule Bibliotheca.Api.AccountController do
  use Bibliotheca.Web, :controller

  import Bibliotheca.Helpers.ErrorExtractor
  import Bibliotheca.Plugs.CaseConverter, only: [conv_case: 2]

  alias Bibliotheca.Account

  @account_not_found "Account Not Found"

  plug :scrub_params, "account" when action in [:create, :update]
  plug :conv_case when action in [:create, :update]

  def index(conn, _param), do:
    render conn, :index, accounts: Account.all

  def create(conn, %{"account" => account_params}), do:
    show_account(conn, User.create(account_params))

  def show conn, %{"id" => id} do
    case User.find id do
      nil     -> account_not_found(conn)
      account -> show_account(conn, account)
    end
  end

  def update(conn, %{"id" => id, "account" => account_params}), do:
    show_account conn, User.update(id, account_params)

  def delete(conn, %{"id" => id}), do:
    resp_no_content conn, User.delete(id)

  defp show_account(conn, ret_param) do
    case ret_param do
      {:ok, account}      -> render conn, :show, account: account
      {:error, changeset} -> client_error conn, changeset
      nil                 -> account_not_found(conn)
    end
  end

  defp resp_no_content(conn, ret_param) do
    case ret_param do
      {:ok, _}            -> send_resp conn, 204, ""
      {:error, changeset} -> client_error conn, changeset
      nil                 -> account_not_found(conn)
    end
  end

  defp client_error(conn, changeset), do:
    conn
    |> put_status(400)
    |> json(%{ errors: extract_errors(changeset)})

  defp account_not_found(conn) do
    conn
    |> put_status(:not_found)
    |> json(%{ error: @account_not_found })
  end
end