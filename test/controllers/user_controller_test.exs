defmodule Bibliotheca.UserControllerTest do
  use Bibliotheca.ConnCase, async: true

  alias Bibliotheca.{Repo, User}
  alias Bibliotheca.Auth.HMAC

  @user1 @user

  test "index/2", %{conn: conn} do
    email2 = "user2@examile.com"
    Repo.insert %User{ @user1 | id: 2, email: email2, password_digest: "foobarbaz", auth_code: "NORMAL" }
    email3 = "user3@examile.com"
    Repo.insert %User{ @user1 | id: 3, email: email3, password_digest: "deadbeed", auth_code: "NORMAL" }

    conn = get(conn, "/api/users/")

    assert (json_response(conn, 200)["users"] |> Enum.sort_by(&(&1["id"]))) == [
      %{ "id" => 1, "email" => @user1.email, "authCode" => "ADMIN" },
      %{ "id" => 2, "email" => email2, "authCode" => "NORMAL" },
      %{ "id" => 3, "email" => email3, "authCode" => "NORMAL" }
    ]
  end

  test "show/2", %{conn: conn} do
    conn = get(conn, "/api/users/#{@user1.id}")

    assert json_response(conn, 200) == %{ "user" => %{ "id" => @user1.id, "email" => @user1.email, "authCode" => @user1.auth_code } }
  end

  test "update/2", %{conn: conn} do
    new_email = "new_email@example.com"
    new_password = "new_password"
    new_auth_code = "NORMAL"

    update_param = %{ email: new_email, password: new_password, auth_code: new_auth_code }
    conn = put(conn, "/api/users/#{@user1.id}", %{ user: update_param })

    assert json_response(conn, 200) == %{ "user" => %{ "id" => @user1.id, "email" => new_email, "authCode" => new_auth_code } }

    new_user = Repo.get User, @user1.id

    assert new_user.email == new_email
    assert new_user.password_digest == HMAC.hexdigest(new_password)
    assert new_user.auth_code == new_auth_code
  end

  test "delete/2", %{conn: conn} do
    delete(conn, "/api/users/#{@user1.id}")

    assert User.find(@user1.id) == nil
  end
end
