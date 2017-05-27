defmodule Bibliotheca.Router do
  use Bibliotheca.Web, :router

  import Bibliotheca.Plugs.{Authorization, Authentication}

  pipeline :api_no_auth do
    plug :accepts, ["json"]
  end

  pipeline :api_normal do
    plug :accepts, ["json"]
    plug :authenticate
    plug :authorize, [:normal]
  end

  pipeline :api_admin do
    plug :accepts, ["json"]
    plug :authenticate
    plug :authorize, [:admin]
  end

  scope "/api", Bibliotheca.Api do
    pipe_through :api_no_auth

    post "/login", AuthenticationController, :login
    get  "/ping",  ApplicationController, :ping
  end

   scope "/api", Bibliotheca.Api do
     pipe_through :api_admin

     resources "/users", UserController, only: [:index, :create, :show, :update, :delete]
     scope "/users" do
       get    "/:user_id/lending", BookController, :lending
       get    "/:user_id/books/lend/:book_id", BookController, :lend
       delete "/:user_id/books/back/:book_id", BookController, :back
     end

     scope "/books" do
       post   "/",           BookController, :create
       delete "/remove/:id", BookController, :remove
     end
   end

   scope "/api", Bibliotheca.Api do
     pipe_through :api_normal

     delete "/logout", AuthenticationController, :logout

     scope "/books" do
       get    "/", BookController, :index
       get    "/lending", BookController, :lending
       get    "/detail/:id", BookController, :show
       get    "/lend/:book_id", BookController, :lend
       delete "/back/:book_id", BookController, :back
     end
   end
end
