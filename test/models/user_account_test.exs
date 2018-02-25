defmodule Bibliotheca.UserAccountTest do
  use Bibliotheca.ModelCase

  alias Bibliotheca.{Repo, Account, User, UserAccount}

  @account %Account{id: 1, name: "account1"}
  @user %User{id: 1, email: "user@example.com", password_digest: "password", auth_code: "ADMIN"}

  @valid_attrs %{account_id: @account.id, user_id: @user.id}
  @invalid_attrs %{}

  describe "changeset" do
    test "changeset with valid attributes." do
      Repo.insert!(@account)
      Repo.insert!(@user)

      changeset = UserAccount.changeset(@valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes." do
      changeset = UserAccount.changeset(@invalid_attrs)
      refute changeset.valid?
    end

    test "changeset with valid attributes but invalid id." do
      changeset = UserAccount.changeset(@valid_attrs)
      refute changeset.valid?
    end
  end

  describe "own?" do
    test "owned" do
      Repo.insert!(@account)
      Repo.insert!(@user)
      Repo.insert!(%UserAccount{account_id: @account.id, user_id: @user.id})

      assert UserAccount.own?(@user.id, @account.id)
    end

    test "not owned" do
      Repo.insert!(@account)
      Repo.insert!(@user)

      refute UserAccount.own?(@user.id, @account.id)
    end
  end

  describe "create" do
    test "add a relation" do
      Repo.insert!(@account)
      Repo.insert!(@user)

      refute UserAccount.own?(@user.id, @account.id)

      assert match?({:ok, _}, UserAccount.create(@user.id, @account.id))

      assert UserAccount.own?(@user.id, @account.id)
    end

    test "try to add a duplicated relation." do
      Repo.insert!(@account)
      Repo.insert!(@user)
      Repo.insert!(%UserAccount{account_id: @account.id, user_id: @user.id})

      assert match?({:error, _}, UserAccount.create(@user.id, @account.id))
    end
  end

  describe "remove" do
    test "remove a relation." do
      Repo.insert!(@account)
      Repo.insert!(@user)
      Repo.insert!(%UserAccount{account_id: @account.id, user_id: @user.id})

      assert UserAccount.own?(@user.id, @account.id)

      assert match?({:ok, _}, UserAccount.delete(@user.id, @account.id))

      refute UserAccount.own?(@user.id, @account.id)
    end

    test "try to remove non associated." do
      Repo.insert!(@account)
      Repo.insert!(@user)

      assert match?({:error, _}, UserAccount.delete(@user.id, @account.id))
    end
  end
end
