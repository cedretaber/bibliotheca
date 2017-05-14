defmodule Bibliotheca.Plugs.AuthorizationTest do
  use Bibliotheca.ConnCase

  import Bibliotheca.Plugs.Authorization

  alias Bibliotheca.User
  alias Bibliotheca.Auth.Token

  setup_all _context do
    Token.init

    user = %User{email: "test@example.com", password_digest: "hogehoge"}
    token = "hogehogefugafuga"

    Token.update_token user, token

    [user: user, token: token]
  end

  test "access success when logged in", %{conn: conn, token: token, user: user} do
    conn = conn
      |> put_req_header(Application.get_env(:bibliotheca, :auth_header), token)
      |> authorize(nil)

    assert conn.assigns[:token] == token
    assert conn.assigns[:current_user] == user
  end

  test "access was refused when not logged in", %{conn: conn} do
    conn = authorize(conn, nil)

    assert conn.status == 403
  end

  test "access was refused when another user logged in", %{conn: conn} do
    conn = conn
      |> put_req_header(Application.get_env(:bibliotheca, :auth_header), "no_such_token")
      |> authorize(nil)

    assert conn.status == 403
  end
end