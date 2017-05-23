defmodule Bibliotheca.Plugs.Authentication do
  import Plug.Conn

  alias Bibliotheca.Auth.Token

  def authenticate(conn, _param) do
    header = Enum.find conn.req_headers, fn {field, _} ->
      String.downcase(field) == Application.get_env(:bibliotheca, :auth_header)
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
        |> send_resp(403, "Unauthorized")
        |> halt()
    end
  end
end