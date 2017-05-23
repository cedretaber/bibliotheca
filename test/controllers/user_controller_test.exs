defmodule Bibliotheca.UserControllerTest do
  use Bibliotheca.ConnCase, async: true

  alias Bibliotheca.{Repo, User}
  alias Bibliotheca.Auth.HMAC

  @user1 @user

  describe "index/2" do
    test "by normal user.", %{conn: conn} do
      email2 = "user2@examile.com"
      user2 = %User{ @user1 | id: 2, email: email2, password_digest: "foobarbaz", auth_code: "NORMAL" }
      Repo.insert user2

      conn = conn
        |> login_user(user2)
        |> get("/api/users/")

      assert conn.status == 403
    end

    test "search all users.", %{conn: conn} do
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
  end

  describe "update/2" do
    test "create a user.", %{conn: conn} do
      new_email = "new_email@example.com"
      new_password = "new_password"
      new_auth_code = "NORMAL"

      create_param = %{ email: new_email, password: new_password, auth_code: new_auth_code }
      conn = post(conn, "/api/users/", %{ user: create_param })

      assert %{ "user" => %{ "id" => id, "email" => ^new_email, "authCode" => ^new_auth_code } } = json_response(conn, 200)

      new_user = Repo.get! User, id

      assert new_user.email == new_email
      assert new_user.password_digest == HMAC.hexdigest(new_password)
      assert new_user.auth_code == new_auth_code
    end

    test "create a user who has a deplecated email.", %{conn: conn} do
      new_password = "new_password"
      new_auth_code = "NORMAL"

      create_param = %{ email: @user1.email, password: new_password, auth_code: new_auth_code }
      conn = post(conn, "/api/users/", %{ user: create_param })

      assert json_response(conn, 400) ==
        (%{ errors: [%{ email: %{ message: "has already been taken", details: [] } }] } |> jsonise())
    end
  end

  describe "show/2" do
    test "show a user.", %{conn: conn} do
      conn = get(conn, "/api/users/#{@user1.id}")

      assert json_response(conn, 200) == %{ "user" => %{ "id" => @user1.id, "email" => @user1.email, "authCode" => @user1.auth_code } }
    end
  end

  describe "update/2" do
    test "update a user.", %{conn: conn} do
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

    test "email duplicated.", %{conn: conn} do
      email2 = "user2@examile.com"
      user2 = %User{ @user1 | id: 2, email: email2, password_digest: "foobarbaz", auth_code: "NORMAL" }
      Repo.insert user2

      update_param = %{ email: user2.email, password: "hogehoge", auth_code: "NORMAL" }

      conn = put(conn, "/api/users/#{@user1.id}", %{ user: update_param })

      assert json_response(conn, 400) ==
        (%{ errors: [%{ email: %{ message: "has already been taken", details: [] } }] } |> jsonise())
    end
  end

  describe "delete/2" do
    test "delete a user.", %{conn: conn} do
      delete(conn, "/api/users/#{@user1.id}")

      assert User.find(@user1.id) == nil
    end
  end
end
