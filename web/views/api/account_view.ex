defmodule Bibliotheca.Api.AccountView do
  use Bibliotheca.Web, :view

  def render("index.json", %{accounts: accounts}),
    do: %{accounts: render_many(accounts, __MODULE__, "account.json")}

  def render("show.json", %{account: account}),
    do: %{account: render_one(account, __MODULE__, "account.json")}

  def render("account.json", %{account: account}),
    do: %{
      id: account.id,
      name: account.name,
      insertedAt: account.inserted_at,
      updatedAt: account.updated_at
    }
end
