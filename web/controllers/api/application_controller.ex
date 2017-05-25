defmodule Bibliotheca.Api.ApplicationController do
  use Bibliotheca.Web, :controller

  def ping(conn, _param), do: send_resp conn, 204, ""
end
