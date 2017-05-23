defmodule Bibliotheca.Api.AuthenticationController do
  use Bibliotheca.Web, :controller

  alias Bibliotheca.User
  alias Bibliotheca.Auth.{HMAC, Token}

  def login(conn, %{"email" => email}) do
    case Repo.get_by(User, email: email) do
      nil ->
        login(conn, nil)
      user ->
        token = HMAC.create_token()

        Token.update_token user, token

        conn
        |> put_resp_header(Application.get_env(:bibliotheca, :auth_header), token)
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