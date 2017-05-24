defmodule Bibliotheca.Plugs.AuthenticationTest do
  use Bibliotheca.ConnCase

  alias Bibliotheca.Auth.Token

  import Bibliotheca.Plugs.Authentication

  test "access success when logged in", %{conn: conn} do
    conn = authenticate(conn, nil)

    assert conn.assigns[:token] == Token.lookup_token(@user.id)
    assert current_user(conn) == @user
  end

  test "access was refused when not logged in", %{conn: conn} do
    conn = conn
      |> delete_req_header(header())
      |> authenticate(nil)

    assert conn.status == 401
  end

  test "access was refused when another user logged in", %{conn: conn} do
    no_such_token = "no_such_token"
    conn = conn
      |> put_req_header(header(), no_such_token)
      |> authenticate(nil)

    assert conn.status == 401
  end
end