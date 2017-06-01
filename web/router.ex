defmodule Bibliotheca.Router do
  use Bibliotheca.Web, :router

  import Bibliotheca.Plugs.Authorization
  import Bibliotheca.Plugs.Authentication, only: [realm: 0]

  pipeline :api_no_auth do
    plug :accepts, ["json"]
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Guardian.Plug.VerifyHeader, realm: realm()
    plug Guardian.Plug.LoadResource
    plug Guardian.Plug.EnsureAuthenticated, handler: Bibliotheca.Plugs.Authentication
  end

  pipeline :api_admin do
    plug :authorize, [:admin]
  end

  pipeline :api_normal do
    plug :authorize, [:normal]
  end

  scope "/api", Bibliotheca.Api do
    pipe_through :api_no_auth

    post "/login", AuthenticationController, :login
    get  "/ping",  ApplicationController, :ping
  end

   scope "/api", Bibliotheca.Api do
     pipe_through :api
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
     pipe_through :api
     pipe_through :api_normal

     scope "/books" do
       get    "/", BookController, :index
       get    "/lending", BookController, :lending
       get    "/detail/:id", BookController, :show
       get    "/lend/:book_id", BookController, :lend
       delete "/back/:book_id", BookController, :back
     end
   end
end
