defmodule Bibliotheca.Router do
  use Bibliotheca.Web, :router

  import Bibliotheca.Plugs.Authorization

#  pipeline :browser do
#    plug :accepts, ["html"]
#    plug :fetch_session
#    plug :fetch_flash
#    plug :protect_from_forgery
#    plug :put_secure_browser_headers
#  end

  pipeline :api_no_auth do
    plug :accepts, ["json"]
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :authorize
  end

  scope "/api", Bibliotheca.Api do
    pipe_through :api_no_auth

    post "/login", AuthenticationController, :login
    get "/ping", ApplicationController, :ping
  end

   scope "/api", Bibliotheca.Api do
     pipe_through :api

     get "/logout", AuthenticationController, :logout

     resources "/users", UserController, only: [:index, :create, :show, :update, :delete]

     scope "/books" do

     end
   end
end
