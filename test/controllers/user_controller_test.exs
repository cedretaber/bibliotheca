defmodule Bibliotheca.UserControllerTest do
  use Bibliotheca.ConnCase, async: true

  alias Bibliotheca.{Repo, User}
  alias Bibliotheca.Auth.HMAC

  @user %User{id: 1,
              email: "test@example.com",
              password_digest: "hogehogefufgafuga",
              auth_code: "ADMIN",
              inserted_at: ~N[2015-04-01 12:00:00],
              updated_at: ~N[2015-04-01 12:00:00]}

  test "index/2", %{conn: conn} do
    email2 = "user2@examile.com"
    Repo.insert %User{ @user | id: 2, email: email2, password_digest: "foobarbaz", auth_code: "NORMAL" }
    email3 = "user3@examile.com"
    Repo.insert %User{ @user | id: 3, email: email3, password_digest: "deadbeed", auth_code: "NORMAL" }

    conn = conn
      |> setup_conn()
      |> get("/api/users/")

    assert (json_response(conn, 200)["users"] |> Enum.sort_by(&(&1["id"]))) == [
      %{ "id" => 1, "email" => @user.email, "authCode" => "ADMIN" },
      %{ "id" => 2, "email" => email2, "authCode" => "NORMAL" },
      %{ "id" => 3, "email" => email3, "authCode" => "NORMAL" }
    ]
  end

  test "show/2", %{conn: conn} do
    conn = conn
      |> setup_conn()
      |> get("/api/users/#{@user.id}")

    assert json_response(conn, 200) == %{ "user" => %{ "id" => @user.id, "email" => @user.email, "authCode" => @user.auth_code } }
  end

  test "update/2", %{conn: conn} do
    new_email = "new_email@example.com"
    new_password = "new_password"
    new_auth_code = "NORMAL"

    update_param = %{ email: new_email, password: new_password, auth_code: new_auth_code }
    conn = conn
      |> setup_conn()
      |> put("/api/users/#{@user.id}", %{ user: update_param })

    assert json_response(conn, 200) == %{ "user" => %{ "id" => @user.id, "email" => new_email, "authCode" => new_auth_code } }

    new_user = Repo.get User, @user.id

    assert new_user.email == new_email
    assert new_user.password_digest == HMAC.hexdigest(new_password)
    assert new_user.auth_code == new_auth_code
  end

  test "delete/2", %{conn: conn} do
    conn
    |> setup_conn()
    |> delete("/api/users/#{@user.id}")

    assert User.find(@user.id) == nil
  end

  defp setup_conn conn do
    header = Application.get_env :bibliotheca, :auth_header
    Repo.insert! @user

    conn = put_req_header conn, "accept", "application/json"

    [token] = conn
      |> post("/api/login", %{email: @user.email})
      |> get_resp_header(header)

    put_req_header conn, header, token
  end
end
