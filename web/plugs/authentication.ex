defmodule Bibliotheca.Plugs.Authentication do
  import Plug.Conn

  alias Bibliotheca.Auth.Token

  def authenticate(conn, _params) do
    header = Enum.find conn.req_headers, fn {field, _} ->
      String.downcase(field) == header()
    end

    with {_, token}                 <- header,
         user when not is_nil(user) <- Token.lookup_user token
    do
      conn
      |> assign(:token, token)
      |> assign(:current_user, user)
    else
      _ ->
        conn
        |> send_resp(401, "Unauthorized")
        |> halt()
    end
  end

  def current_user(conn), do: conn.assigns[:current_user]
  def header, do: Application.get_env(:bibliotheca, :auth_header) |> String.downcase()
end