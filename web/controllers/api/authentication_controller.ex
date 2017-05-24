defmodule Bibliotheca.Api.AuthenticationController do
  use Bibliotheca.Web, :controller

  alias Bibliotheca.User
  alias Bibliotheca.Auth.{HMAC, Token}

  import Bibliotheca.Plugs.Authentication, only: [current_user: 1]

  plug :scrub_params, "email" when action in [:login]
  plug :scrub_params, "password" when action in [:login]

  def login(conn, %{"email" => email, "password" => password}) do
    case Repo.get_by(User, email: email) do
      nil ->
        login(conn, nil)
      user ->
        if user.password_digest == HMAC.hexdigest(password) do
          token = Token.create_token()

          Token.update_token user, token

          conn
          |> put_resp_header(Application.get_env(:bibliotheca, :auth_header), token)
          |> send_resp(204, "")
        else
          login(conn, nil)
        end
    end
  end

  def login(conn, _param) , do: send_resp(conn, 401, "")

  def logout(conn, _param) do
    Token.delete_token current_user(conn).id
    send_resp conn, 204, ""
  end
end