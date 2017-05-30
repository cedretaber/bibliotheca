defmodule Bibliotheca.AuthenticationControllerTest do
  use Bibliotheca.ConnCase, async: true

  alias Bibliotheca.Auth.Token

  import Bibliotheca.Plugs.Authentication, only: [header: 0]

  @password1 @password
  @user1 @user

  describe "login" do
    test "login with valid email and password." do
      login_param = %{ email: @user1.email, password: @password1 }

      conn =
       build_conn()
       |> post("/api/login", login_param)

      assert conn.status == 204
      [token] = get_resp_header(conn, header())
      assert token == Token.lookup_token(@user1.id)
    end

    test "login with invalid email." do
      login_param = %{ email: "nosuchemail@example.com", password: @password1 }

      conn =
       build_conn()
       |> post("/api/login", login_param)

      assert conn.status == 401
    end

    test "login with invalid password." do
      login_param = %{ email: @user1.email, password: "invalid_password" }

      conn =
       build_conn()
       |> post("/api/login", login_param)

      assert conn.status == 401
    end
  end

  describe "logout" do
    test "logout success.", %{conn: conn} do
      [token] = get_req_header(conn, header())
      assert Token.lookup_user_id(token) == @user1.id
      assert Token.lookup_token(@user1.id) == token

      conn = delete(conn, "/api/logout")

      assert conn.status == 204
      refute Token.lookup_user_id(token)
      refute Token.lookup_token(@user1.id)
    end
  end
end