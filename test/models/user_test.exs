defmodule Bibliotheca.UserTest do
  use Bibliotheca.ModelCase

  alias Bibliotheca.User
  alias Bibliotheca.Auth.HMAC

  @invalid_attrs %{}

  describe "changeset" do
    test "changeset with valid attributes" do
      valid_attrs = %{deleted_at: ~N[2016-04-01 12:00:00],
                      email: "test@example.com",
                      password_digest: "hogehogefufgafuga",
                      auth_code: "ADMIN"}
      changeset = User.changeset(%User{}, valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = User.changeset(%User{}, @invalid_attrs)
      refute changeset.valid?
    end

    test "changeset(email) with valid attributes" do
      changeset = User.changeset(%User{}, %{ email: "test@example.com" })
      assert changeset.valid?
    end

    test "changeset(password) with valid attributes" do
      changeset = User.changeset(%User{}, %{ password_digest: "hogehogefugafuga" })
      assert changeset.valid?
    end
  end

  alias Bibliotheca.Repo

  describe "all" do
    test "all" do
      user = %User{id: 1,
                   email: "test@example.com",
                   password_digest: "hogehogefufgafuga",
                   auth_code: "ADMIN",
                   inserted_at: ~N[2015-04-01 12:00:00],
                   updated_at: ~N[2015-04-01 12:00:00]}
      users = [
        %User{user | email: "user1@example.com", password_digest: "user1", auth_code: "ADMIN"},
        %User{user | id: 2, email: "user2@example.com", password_digest: "user2", auth_code: "NORMAL"},
        %User{user | id: 3, email: "user3@example.com", password_digest: "user3", auth_code: "NORMAL"},
        %User{user | id: 4, email: "user4@example.com", password_digest: "user4", auth_code: "NORMAL"}
      ]

      Enum.each users, fn user -> Repo.insert! user end

      User.all()
      |> Enum.zip(users)
      |> Enum.each(fn {ret, exp} ->
        assert ret.email == exp.email
        assert ret.password_digest == exp.password_digest
        assert ret.auth_code == exp.auth_code
      end)
    end
  end

  describe "create" do
    test "create" do
      email = "user@example.com"
      user_param = %{ "email" => email, "password" => "user", "auth_code" => "ADMIN" }

      assert Repo.get_by(User, email: email) == nil

      assert {:ok, _} = User.create user_param

      assert Repo.get_by(User, email: email) != nil
    end

    test "when a email duplicated." do
      email = "user@example.com"

      user1 = %User{ id: 1, email: email, password_digest: "hogehoge", auth_code: "ADMIN" }
      Repo.insert! user1

      user_param = %{ "email" => email, "password" => "user", "auth_code" => "ADMIN" }

      assert {:error, changeset} = User.create(user_param)
      assert changeset.errors == [email: {"has already been taken", []}]
    end
  end

  describe "find" do
    test "find" do
      datetime = ~N[2015-04-01 13:00:00]
      email = "user@example.com"

      Repo.insert! %User{ email: email, password_digest: "user", auth_code: "ADMIN", inserted_at: datetime, updated_at: datetime }
      id = Repo.get_by(User, email: email).id

      assert User.find(id) != nil
    end

    test "find with nonexists user" do
      id = 42
      assert User.find(id) == nil
    end

    test "find_by_email" do
      datetime = ~N[2015-04-01 13:00:00]
      email = "user@example.com"

      Repo.insert! %User{ email: email, password_digest: "user", auth_code: "ADMIN", inserted_at: datetime, updated_at: datetime }

      assert User.find_by_email(email) != nil
    end

    test "find_by_email with nonexists user" do
      email = "nonexists@example.com"
      assert User.find_by_email(email) == nil
    end
  end

  describe "update" do
    test "update" do
      id = 42
      now = ~N[2015-04-01 12:00:00.000000]
      user = %User{id: id,
                   email: "user@example.com",
                   password_digest: "hogehogefugafuga",
                   auth_code: "NORMAL",
                   inserted_at: now,
                   updated_at: now}

      Repo.insert! user

      email = "another-user@example.com"
      password = "foobarbaz"
      auth_code = "ADMIN"

      update_param = %{ "email" => email, "password" => password, "auth_code" => auth_code }
      assert {:ok, _} = User.update(id, update_param)

      user = Repo.get!(User, id)
      assert user.email == email
      assert user.password_digest == HMAC.hexdigest(password)
      assert user.auth_code == auth_code
      assert user.inserted_at == now
      refute user.updated_at == now
    end

    test "update when the email duplicated." do
      user1 = %User{id: 1, email: "user@example.com", password_digest: "hogehogefugafuga", auth_code: "NORMAL",}
      Repo.insert! user1

      user2 = %User{ user1 | id: 2, email: "user2@example.com" }
      Repo.insert! user2

      update_param = %{ "email" => user1.email, "password" => "fugafuga", "auth_code" => "ADMIN" }

      assert {:error, changeset} = User.update(user2.id, update_param)
      assert changeset.errors == [email: {"has already been taken", []}]
    end

    test "update_email" do
      id = 42
      user = %User{id: id,
                   email: "user@example.com",
                   password_digest: "hogehogefugafuga",
                   auth_code: "NORMAL",
                   inserted_at: ~N[2015-04-01 12:00:00],
                   updated_at: ~N[2015-04-01 12:00:00]}

      Repo.insert! user

      email = "another-user@example.com"
      User.update_email(id, email)

      new_user = Repo.get!(User, id)
      assert new_user.email == email
      assert new_user.password_digest == user.password_digest
      assert new_user.auth_code == user.auth_code
    end

    test "update_password" do
      id = 42
      user = %User{id: id,
                   email: "user@example.com",
                   password_digest: "hogehogefugafuga",
                   auth_code: "NORMAL",
                   inserted_at: ~N[2015-04-01 12:00:00],
                   updated_at: ~N[2015-04-01 12:00:00]}

      Repo.insert! user

      password = "foobarbaz"
      User.update_password(id, password)

      new_user = Repo.get!(User, id)
      assert new_user.email == user.email
      assert new_user.password_digest == HMAC.hexdigest(password)
      assert new_user.auth_code == user.auth_code
    end
  end

  describe "delete" do
    test "delete" do
      id = 99
      user = %User{id: id,
                   email: "user@example.com",
                   password_digest: "hogehogefugafuga",
                   auth_code: "NORMAL",
                   inserted_at: ~N[2015-04-01 12:00:00],
                   updated_at: ~N[2015-04-01 12:00:00]}

      Repo.insert! user
      assert Repo.get(User, id) != nil
      assert User.find(id) != nil

      assert match? {:ok, _}, User.delete(id)

      assert Repo.get(User, id) == nil
      assert User.find(id) == nil
    end

    test "try delete nonexists user." do
      id = 42

      assert match? {:error, _}, User.delete(id)
    end
  end
end
