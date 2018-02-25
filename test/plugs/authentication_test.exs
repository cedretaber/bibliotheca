defmodule Bibliotheca.Plugs.AuthenticationTest do
  use Bibliotheca.ConnCase

  import Bibliotheca.Plugs.Authentication

  test "access was refused", %{conn: conn} do
    assert unauthenticated(conn, nil).status == 401
  end
end
