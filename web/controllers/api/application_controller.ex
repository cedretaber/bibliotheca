defmodule Bibliotheca.Api.ApplicationController do
  use Bibliotheca.Web, :controller

  def ping(conn, _param) do
    json conn, %{ok: true}
  end
end
