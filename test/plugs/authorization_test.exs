defmodule Bibliotheca.Plugs.AuthorizationTest do
  use Bibliotheca.ConnCase

  import Bibliotheca.Plugs.Authorization

  alias Bibliotheca.Auth.Token

  @header Application.get_env(:bibliotheca, :auth_header)

  test "access success when logged in", %{conn: conn} do
    conn = authorize(conn, nil)

    assert conn.assigns[:token] == Token.lookup_token(@user.id)
    assert conn.assigns[:current_user] == @user
  end

  test "access was refused when not logged in", %{conn: conn} do
    conn = conn
      |> delete_req_header(@header)
      |> authorize(nil)

    assert conn.status == 403
  end

  test "access was refused when another user logged in", %{conn: conn} do
    no_such_token = "no_such_token"
    conn = conn
      |> update_req_header(@header, no_such_token, fn _ -> no_such_token end)
      |> authorize(nil)

    assert conn.status == 403
  end
end