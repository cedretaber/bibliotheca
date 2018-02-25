defmodule Bibliotheca.UserControllerTest do
  use Bibliotheca.ConnCase, async: true

  alias Bibliotheca.{Repo, User}
  alias Bibliotheca.Auth.HMAC

  @user1 @user

  describe "index/2" do
    test "by normal user.", %{conn: conn} do
      email2 = "user2@examile.com"

      user2 = %User{
        @user1
        | id: 2,
          email: email2,
          password_digest: "foobarbaz",
          auth_code: "NORMAL"
      }

      Repo.insert(user2)

      conn =
        conn
        |> login_user(user2)
        |> get("/api/users/")

      assert conn.status == 403
    end

    test "search all users.", %{conn: conn} do
      email2 = "user2@examile.com"

      Repo.insert(%User{
        @user1
        | id: 2,
          email: email2,
          password_digest: "foobarbaz",
          auth_code: "NORMAL"
      })

      email3 = "user3@examile.com"

      Repo.insert(%User{
        @user1
        | id: 3,
          email: email3,
          password_digest: "deadbeed",
          auth_code: "NORMAL"
      })

      conn = get(conn, "/api/users/")

      [user1, user2, user3] = json_response(conn, 200)["users"] |> Enum.sort_by(& &1["id"])
      email1 = @user1.email

      assert match?(
               %{
                 "id" => 1,
                 "email" => ^email1,
                 "authCode" => "ADMIN",
                 "insertedAt" => "2015-04-01T12:00:00.000000",
                 "updatedAt" => _
               },
               user1
             )

      assert match?(
               %{
                 "id" => 2,
                 "email" => ^email2,
                 "authCode" => "NORMAL",
                 "insertedAt" => "2015-04-01T12:00:00.000000",
                 "updatedAt" => _
               },
               user2
             )

      assert match?(
               %{
                 "id" => 3,
                 "email" => ^email3,
                 "authCode" => "NORMAL",
                 "insertedAt" => "2015-04-01T12:00:00.000000",
                 "updatedAt" => _
               },
               user3
             )
    end
  end

  describe "create/2" do
    test "create a user.", %{conn: conn} do
      new_email = "new_email@example.com"
      new_password = "new_password"
      new_auth_code = "NORMAL"

      create_param = %{email: new_email, password: new_password, auth_code: new_auth_code}

      conn = post(conn, "/api/users/", %{user: create_param})

      assert %{"user" => %{"id" => id, "email" => ^new_email, "authCode" => ^new_auth_code}} =
               json_response(conn, 200)

      new_user = Repo.get!(User, id)

      assert new_user.email == new_email
      assert HMAC.verify_password(new_user.password_digest, new_password)
      assert new_user.auth_code == new_auth_code
    end

    test "create a user who has a duplicated email.", %{conn: conn} do
      new_password = "new_password"
      new_auth_code = "NORMAL"

      create_param = %{email: @user1.email, password: new_password, auth_code: new_auth_code}
      conn = post(conn, "/api/users/", %{user: create_param})

      assert json_response(conn, 400) ==
               %{errors: [%{email: %{message: "has already been taken", details: []}}]}
               |> jsonise()
    end

    test "create a user with camelCase params.", %{conn: conn} do
      new_email = "new_email@example.com"
      new_password = "new_password"
      new_auth_code = "NORMAL"

      create_param = %{email: new_email, password: new_password, authCode: new_auth_code}

      conn = post(conn, "/api/users/", %{user: create_param})

      assert %{"user" => %{"id" => id, "email" => ^new_email, "authCode" => ^new_auth_code}} =
               json_response(conn, 200)

      new_user = Repo.get!(User, id)

      assert new_user.email == new_email
      assert HMAC.verify_password(new_user.password_digest, new_password)
      assert new_user.auth_code == new_auth_code
    end
  end

  describe "show/2" do
    test "show a user.", %{conn: conn} do
      conn = get(conn, "/api/users/#{@user1.id}")

      id1 = @user1.id
      email1 = @user1.email
      auth_code1 = @user1.auth_code

      assert match?(
               %{
                 "user" => %{
                   "id" => ^id1,
                   "email" => ^email1,
                   "authCode" => ^auth_code1,
                   "insertedAt" => "2015-04-01T12:00:00.000000",
                   "updatedAt" => _
                 }
               },
               json_response(conn, 200)
             )
    end

    test "show nonexistent user.", %{conn: conn} do
      conn = get(conn, "/api/users/42")

      assert json_response(conn, 404) == %{error: "User Not Found"} |> jsonise()
    end
  end

  describe "update/2" do
    test "update a user.", %{conn: conn} do
      new_email = "new_email@example.com"
      new_password = "new_password"
      new_auth_code = "NORMAL"

      update_param = %{email: new_email, password: new_password, auth_code: new_auth_code}
      conn = put(conn, "/api/users/#{@user1.id}", %{user: update_param})

      id1 = @user1.id

      assert match?(
               %{
                 "user" => %{
                   "id" => ^id1,
                   "email" => ^new_email,
                   "authCode" => ^new_auth_code,
                   "insertedAt" => "2015-04-01T12:00:00.000000",
                   "updatedAt" => _
                 }
               },
               json_response(conn, 200)
             )

      new_user = Repo.get(User, @user1.id)

      assert new_user.email == new_email
      assert HMAC.verify_password(new_user.password_digest, new_password)
      assert new_user.auth_code == new_auth_code
    end

    test "email duplicated.", %{conn: conn} do
      email2 = "user2@examile.com"

      user2 = %User{
        @user1
        | id: 2,
          email: email2,
          password_digest: "foobarbaz",
          auth_code: "NORMAL"
      }

      Repo.insert(user2)

      update_param = %{email: user2.email, password: "hogehoge", auth_code: "NORMAL"}

      conn = put(conn, "/api/users/#{@user1.id}", %{user: update_param})

      assert json_response(conn, 400) ==
               %{errors: [%{email: %{message: "has already been taken", details: []}}]}
               |> jsonise()
    end

    test "update nonexistent user.", %{conn: conn} do
      update_param = %{email: "hoge@example.com", password: "hogehoge", auth_code: "NORMAL"}

      conn = put(conn, "/api/users/42", %{user: update_param})

      assert json_response(conn, 404) == %{error: "User Not Found"} |> jsonise()
    end

    test "update a user with camelCase param.", %{conn: conn} do
      new_email = "new_email@example.com"
      new_password = "new_password"
      new_auth_code = "NORMAL"

      update_param = %{email: new_email, password: new_password, authCode: new_auth_code}
      conn = put(conn, "/api/users/#{@user1.id}", %{user: update_param})

      id1 = @user1.id

      assert match?(
               %{
                 "user" => %{
                   "id" => ^id1,
                   "email" => ^new_email,
                   "authCode" => ^new_auth_code,
                   "insertedAt" => "2015-04-01T12:00:00.000000",
                   "updatedAt" => _
                 }
               },
               json_response(conn, 200)
             )

      new_user = Repo.get(User, @user1.id)

      assert new_user.email == new_email
      assert HMAC.verify_password(new_user.password_digest, new_password)
      assert new_user.auth_code == new_auth_code
    end
  end

  describe "delete/2" do
    test "delete a user.", %{conn: conn} do
      conn = delete(conn, "/api/users/#{@user1.id}")

      assert conn.status == 204
      assert User.find(@user1.id) == nil
    end

    test "delete nonexistent user.", %{conn: conn} do
      conn = delete(conn, "/api/users/42")

      assert json_response(conn, 404) == %{error: "User Not Found"} |> jsonise()
    end
  end
end
