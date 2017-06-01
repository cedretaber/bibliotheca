defmodule Bibliotheca.Plugs.Authentication do
  import Plug.Conn

  @realm "Bibliotheca"

  def realm, do: @realm

  def unauthenticated(conn, _param), do:
    conn
    |> send_resp(401, "Unauthorized")
    |> halt()

  def current_user(conn), do: Guardian.Plug.current_resource(conn)

  def header, do: Application.get_env(:bibliotheca, :auth_header) |> String.downcase()
end