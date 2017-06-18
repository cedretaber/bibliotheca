defmodule Bibliotheca.Api.AuthenticationController do
  use Bibliotheca.Web, :controller

  alias Bibliotheca.Auth.HMAC
  alias Bibliotheca.User

  import Bibliotheca.Plugs.Authentication, only: [realm: 0, header: 0]

  plug :scrub_params, "email" when action in [:login]
  plug :scrub_params, "password" when action in [:login]

  def login(conn, %{"email" => email, "password" => password}) do
    case Repo.get_by(User, email: email) do
      nil ->
        login(conn, nil)
      user ->
        if HMAC.verify_password(user.password_digest, password) do
          conn   = Guardian.Plug.api_sign_in conn, user
          jwt    = Guardian.Plug.current_token conn

          conn
          |> put_resp_header(header(), "#{realm()} #{jwt}")
          |> send_resp(204, "")
        else
          login(conn, nil)
        end
    end
  end

  def login(conn, _param) , do: send_resp(conn, 401, "")
end