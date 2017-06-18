defmodule Bibliotheca.AccountTest do
  use Bibliotheca.ModelCase

  alias Bibliotheca.{Account, User}

  @valid_attr %{name: "account1"}
  @account %Account{id: 1, name: "account1", inserted_at: ~N[2015-04-01 12:00:00], updated_at: ~N[2015-04-01 12:00:00]}
  @user %User{id: 1,
              email: "test@example.com",
              password_digest: "hogehogefufgafuga",
              auth_code: "ADMIN",
              inserted_at: ~N[2015-04-01 12:00:00],
              updated_at: ~N[2015-04-01 12:00:00]}

  describe "changeset" do
    test "changeset with valid attributes." do
      changeset = Account.changeset(%Account{}, @valid_attr)
      assert changeset.valid?
    end

    test "changeset with valid attributes and users." do
      users = [@user]
      changeset = Account.changeset(%Account{}, @valid_attr, users)
      assert changeset.valid?
    end

    test "changeset with invalid attributes." do
      invalid_attr = %{}
      changeset = Account.changeset(%Account{}, invalid_attr)
      refute changeset.valid?
    end
  end


  describe "all" do
    test "query all accounts." do
      account1 = @account
      account2 = %Account{account1 | id: 2, name: "account2"}
      account3 = %Account{account1 | id: 3, name: "account3"}
      list = [account1, account2, account3]

      list
      |> Enum.each(fn account -> Repo.insert! account end)

      Account.all()
      |> Enum.zip(list)
      |> Enum.each(fn {ret, exp} -> assert ret.name == exp.name end)
    end

    test "query all undeleted accounts." do
      account1 = %Account{id: 1, name: "account1", inserted_at: ~N[2015-04-01 12:00:00], updated_at: ~N[2015-04-01 12:00:00]}
      account2 = %Account{account1 | id: 2, name: "account2", deleted_at: ~N[2016-04-01 12:00:00]}
      account3 = %Account{account1 | id: 3, name: "account3"}
      list = [account1, account2, account3]

      list
      |> Enum.each(fn account -> Repo.insert! cast(account, %{}, []) end)

      list = [account1, account3]

      Account.all()
      |> Enum.zip(list)
      |> Enum.each(fn {ret, exp} -> assert ret.name == exp.name end)
    end

    test "return empty list when there are no account." do
      assert Enum.empty?(Account.all())
    end

    test "get all accounts with users." do
      user1 = @user
      user2 = %User{user1 | id: 2, email: "test2@example.com"}
      user3 = %User{user1 | id: 3, email: "test3@example.com"}

      [user1, user2, user3]
      |> Enum.each(fn user -> Repo.insert! user end)

      account1 = %Account{id: 1,
                          name: "account1",
                          inserted_at: ~N[2015-04-01 12:00:00],
                          updated_at: ~N[2015-04-01 12:00:00]}
      account2 = %Account{account1 | id: 2, name: "account2"}
      account3 = %Account{account1 | id: 3, name: "account3"}
      list = [account1, account2, account3]

      user_assoc = [[1, 2], [2], [3]]

      list
      |> Enum.zip(user_assoc)
      |> Enum.each(fn {account, users} ->
        changeset = account |> change |> put_assoc(:users, users |> Enum.map(fn id -> Repo.get(User, id) end))
        Repo.insert! changeset
      end)

      Account.all()
      |> Enum.zip(list)
      |> Enum.zip(user_assoc)
      |> Enum.each(fn {{ret, exp}, users} ->
        assert ret.name == exp.name
        assert length(ret.users) == length(users)
        ret.users
        |> Enum.zip(users)
        |> Enum.each(fn {ret, exp_id} -> assert ret.id == exp_id end)
      end)
    end
  end

  @valid_param %{name: "account1"}

  describe "create" do
    test "create an account without user." do
      refute Repo.get_by(Account, name: @valid_param[:name])

      assert {:ok, account} = Account.create(@valid_param)
      assert account == Repo.get_by(Account, name: @valid_param[:name])
    end

    test "create an account with user." do
      Repo.insert! @user
      users = [Repo.get(User, @user.id)]

      refute Repo.get_by(Account, name: @valid_param[:name])

      assert {:ok, account} = Account.create(@valid_param, users)
      assert account.users == users
    end

    test "creation failed with invalid params." do
      param = %{}

      assert match? {:error, _}, Account.create(param)
    end

    test "creation failed with ivalid users." do
      user = %User{@user | id: 42}

      Account.create(@valid_param, [user])

      assert match? {:error, _}, Account.create(@valid_param, [user])
    end
  end

  describe "find" do
    test "find an account." do
      Repo.insert! @account

      account = Account.find @account.id

      assert @account.id == account.id
      assert @account.name == account.name
    end

    test "try to find nonexistent account." do
      refute Account.find(42)
    end
  end

  describe "find_by_name" do
    test "find an account." do
      Repo.insert! @account

      account = Account.find_by_name @account.name

      assert @account.id == account.id
      assert @account.name == account.name
    end

    test "try to find nonexistent account." do
      refute Account.find_by_name("no such account")
    end
  end

  describe "update" do
    test "update an account successfully." do
      Repo.insert! @account

      new_name = "new name"
      param = %{ "name" => new_name }

      assert {:ok, account} = Account.update(@account.id, param)
      assert account.name == new_name

      account = Repo.get Account, @account.id
      assert account.name == new_name
    end

    test "try to update nonexistent account." do
      new_name = "new name"
      param = %{ "name" => new_name }

      refute Account.update(42, param)
    end
  end

  describe "delete" do
    test "delete an account." do
      Repo.insert! @account

      assert match? {:ok, _}, Account.delete(@account.id)

      account = Repo.get Account, @account.id
      assert account
      assert account.deleted_at
      refute Account.find(@account.id)
      refute Account.find_by_name(@account.name)
    end

    test "try to delete nonexistent account." do
      refute Account.delete(42)
    end
  end
end