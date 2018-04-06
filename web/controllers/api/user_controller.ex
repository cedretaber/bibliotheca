defmodule Bibliotheca.Api.UserController do
  use Bibliotheca.Web, :controller

  import Bibliotheca.Helpers.ErrorExtractor
  import Bibliotheca.Plugs.CaseConverter, only: [conv_case: 2]

  alias Bibliotheca.User

  @user_not_found "User Not Found"

  plug :scrub_params, "user" when action in [:create, :update]
  plug :conv_case when action in [:create, :update]

  def index(conn, _param), do: render(conn, :index, users: User.all())

  def create(conn, %{"user" => user_params}), do: show_user(conn, User.create(user_params))

  def show(conn, %{"id" => id}) do
    show_user(
      conn,
      case User.find(id) do
        nil -> nil
        user -> {:ok, user}
      end
    )
  end

  def update(conn, %{"id" => id, "user" => user_params}),
    do: show_user(conn, User.update(id, user_params))

  def delete(conn, %{"id" => id}), do: resp_no_content(conn, User.delete(id))

  defp show_user(conn, ret_param) do
    case ret_param do
      {:ok, user} -> render(conn, :show, user: user)
      {:error, changeset} -> client_error(conn, changeset)
      nil -> user_not_found(conn)
    end
  end

  defp resp_no_content(conn, ret_param) do
    case ret_param do
      {:ok, _} -> send_resp(conn, 204, "")
      {:error, changeset} -> client_error(conn, changeset)
      nil -> user_not_found(conn)
    end
  end

  defp client_error(conn, changeset),
    do:
      conn
      |> put_status(400)
      |> json(%{errors: extract_errors(changeset)})

  defp user_not_found(conn) do
    conn
    |> put_status(:not_found)
    |> json(%{error: @user_not_found})
  end
end
