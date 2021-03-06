defmodule Bibliotheca.Plugs.AuthorizationTest do
  use Bibliotheca.ConnCase

  import Bibliotheca.Plugs.Authorization

  alias Bibliotheca.User

  @user1 @user
  @user2 %User{@user1 | id: 2, email: "user2@example.com", auth_code: "NORMAL"}

  test "access admin resources by admin user.", %{conn: conn} do
    conn = authorize(conn, [:admin])

    refute conn.halted
  end

  test "access admin resources by normal user.", %{conn: conn} do
    Repo.insert!(@user2)

    conn =
      conn
      |> login_user(@user2)
      |> authorize([:admin])

    assert conn.halted
  end

  test "access normal resources.", %{conn: conn} do
    Repo.insert!(@user2)

    conn_admin = authorize(conn, [:normal])
    refute conn_admin.halted

    conn_normal =
      conn
      |> login_user(@user2)
      |> authorize([:normal])

    refute conn_normal.halted
  end
end
