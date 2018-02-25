defmodule Bibliotheca.AuthenticationControllerTest do
  use Bibliotheca.ConnCase, async: true

  import Bibliotheca.Plugs.Authentication, only: [realm: 0, header: 0]

  @password1 @password
  @user1 @user

  describe "login" do
    test "login with valid email and password." do
      login_param = %{email: @user1.email, password: @password1}

      conn =
        build_conn()
        |> post("/api/login", login_param)

      assert conn.status == 204

      [token] = get_resp_header(conn, header())
      jwt = Guardian.Plug.current_token(conn)
      assert token == "#{realm()} #{jwt}"
    end

    test "login with invalid email." do
      login_param = %{email: "nosuchemail@example.com", password: @password1}

      conn =
        build_conn()
        |> post("/api/login", login_param)

      assert conn.status == 401
    end

    test "login with invalid password." do
      login_param = %{email: @user1.email, password: "invalid_password"}

      conn =
        build_conn()
        |> post("/api/login", login_param)

      assert conn.status == 401
    end
  end
end
