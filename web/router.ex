defmodule Bibliotheca.Router do
  use Bibliotheca.Web, :router

  import Bibliotheca.Plugs.Authorization
  import Bibliotheca.Plugs.Authentication, only: [realm: 0]

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug Guardian.Plug.VerifyHeader, realm: realm()
    plug Guardian.Plug.LoadResource
    plug Guardian.Plug.EnsureAuthenticated, handler: Bibliotheca.Plugs.Authentication
  end

  pipeline :admin do
    plug :authorize, [:admin]
  end

  pipeline :normal do
    plug :authorize, [:normal]
  end

  # 認証無し
  scope "/api", Bibliotheca.Api do
     pipe_through :api

    post "/login", AuthenticationController, :login
    get  "/ping",  ApplicationController, :ping
  end

  # 認証あり（管理者）
  scope "/api", Bibliotheca.Api do
    pipe_through :api
    pipe_through :auth
    pipe_through :admin

    resources "/users", UserController, only: [:index, :create, :show, :update, :delete]
    scope "/users" do
      get    "/:id/accounts/:account_id", UserController, :add_account
      delete "/:id/accounts/:account_id", UserController, :remove_account
    end

    resources "/accounts", AccountController, only: [:index, :create, :show, :update, :delete]

    scope "/books" do
      post   "/",             BookController, :create
      get    "/:id/lending/", BookController, :lending
      delete "/:id",          BookController, :remove
    end
  end

  # 認証あり（一般）
  scope "/api", Bibliotheca.Api do
    pipe_through :api
    pipe_through :auth
    pipe_through :normal

    scope "/accounts" do
      get    "/:id/books/:book_id", AccountController, :lend
      delete "/:id/books/:book_id", AccountController, :back
    end

    scope "/books" do
      get "/",    BookController, :index
      get "/:id", BookController, :show
    end
  end
end
