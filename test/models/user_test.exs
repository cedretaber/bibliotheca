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

    test "changeset_email with valid attributes" do
      changeset = User.changeset_email(%User{}, %{ email: "test@example.com" })
      assert changeset.valid?
    end

    test "changeset_email with invalid attributes" do
      changeset = User.changeset_email(%User{}, @invalid_attrs)
      refute changeset.valid?
    end

    test "changeset_password with valid attributes" do
      changeset = User.changeset_password(%User{}, %{ password_digest: "hogehogefugafuga" })
      assert changeset.valid?
    end

    test "changeset_password with invalid attributes" do
      changeset = User.changeset_password(%User{}, @invalid_attrs)
      refute changeset.valid?
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
        %User{ user | email: "user1@example.com", password_digest: "user1", auth_code: "ADMIN" },
        %User{ user | id: 2, email: "user2@example.com", password_digest: "user2", auth_code: "NORMAL" },
        %User{ user | id: 3, email: "user3@example.com", password_digest: "user3", auth_code: "NORMAL", deleted_at: ~N[2015-04-01 13:00:00] },
        %User{ user | id: 4, email: "user4@example.com", password_digest: "user4", auth_code: "NORMAL" }
      ]

      Enum.each users, fn user -> Repo.insert! user end

      User.all()
      |> Enum.zip(Enum.filter users, fn %User{deleted_at: nil} -> true; _ -> false end)
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

      User.create user_param

      assert Repo.get_by(User, email: email) != nil
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

    test "find with deleted user" do
      datetime = ~N[2015-04-01 13:00:00]
      email = "user@example.com"

      Repo.insert! %User{ email: email, password_digest: "user", auth_code: "ADMIN", inserted_at: datetime, updated_at: datetime, deleted_at: datetime }
      id = Repo.get_by(User, email: email).id

      assert User.find(id) == nil
    end

    test "find_by_email" do
      datetime = ~N[2015-04-01 13:00:00]
      email = "user@example.com"

      Repo.insert! %User{ email: email, password_digest: "user", auth_code: "ADMIN", inserted_at: datetime, updated_at: datetime }

      assert User.find_by_email(email) != nil
    end

    test "find_by_email with deleted user" do
      datetime = ~N[2015-04-01 13:00:00]
      email = "user@example.com"

      Repo.insert! %User{ email: email, password_digest: "user", auth_code: "ADMIN", inserted_at: datetime, updated_at: datetime, deleted_at: datetime }

      assert User.find_by_email(email) == nil
    end
  end

  describe "update" do
    test "update" do
      id = 42
      user = %User{id: id,
                   email: "user@example.com",
                   password_digest: "hogehogefugafuga",
                   auth_code: "NORMAL",
                   inserted_at: ~N[2015-04-01 12:00:00],
                   updated_at: ~N[2015-04-01 12:00:00]}

      Repo.insert! user

      email = "another-user@example.com"
      password = "foobarbaz"
      auth_code = "ADMIN"

      update_param = %{ "email" => email, "password" => password, "auth_code" => auth_code }
      User.update(id, update_param)

      user = Repo.get!(User, id)
      assert user.email == email
      assert user.password_digest == HMAC.hexdigest(password)
      assert user.auth_code == auth_code
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

      user = Repo.get!(User, id)
      assert user.email == email
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

      user = Repo.get!(User, id)
      assert user.password_digest == HMAC.hexdigest(password)
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

      User.delete id

      assert Repo.get(User, id) != nil
      assert User.find(id) == nil
    end
  end
end
