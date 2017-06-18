defmodule Bibliotheca.Api.UserView do
  use Bibliotheca.Web, :view

  def render("index.json", %{users: users}), do:
    %{ users: render_many(users, __MODULE__, "user.json") }

  def render("show.json", %{user: user}), do:
    %{ user: render_one(user, __MODULE__, "user.json") }

  def render("user.json", %{user: user}), do:
    %{id: user.id,
      email: user.email,
      authCode: user.auth_code,
      insertedAt: user.inserted_at,
      updatedAt: user.updated_at}
end