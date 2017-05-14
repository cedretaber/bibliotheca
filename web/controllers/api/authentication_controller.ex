defmodule Bibliotheca.Api.AuthenticationController do
  use Bibliotheca.Web, :controller

  import Ecto.Query

  alias Bibliotheca.User
  alias Bibliotheca.Auth.Token

  def login(conn, %{"email" => email}) do
    user = Repo.one from u in User, where: u.email == ^email
    case user do
      nil ->
        login(conn, %{})
      user ->
        token =
          :crypto.strong_rand_bytes(32)
          |> Base.encode64
          |> binary_part(0, 32)

        Token.update_token user, token

        conn
        |> put_resp_header("bibliotheca-token", token)
        |> send_resp(204, "")
    end
  end

  def login(conn, _param) , do:
    conn
    |> send_resp(403, "")

  def logout(conn, _param) do
    Token.delete_token conn.assigns[:current_user].id
    send_resp conn, 204, ""
  end
end