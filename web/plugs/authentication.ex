defmodule Bibliotheca.Plugs.Authentication do
  import Plug.Conn

  alias Bibliotheca.{User, Repo}
  alias Bibliotheca.Auth.Token

  def authenticate(conn, _params) do
    header = Enum.find conn.req_headers, fn {field, _} ->
      String.downcase(field) == header()
    end

    with {_, token}                       <- header,
         user_id when not is_nil(user_id) <- Token.lookup_user_id token
    do
      put_private(conn, __MODULE__, user_id)
    else
      _ ->
        conn
        |> send_resp(401, "Unauthorized")
        |> halt()
    end
  end

  def current_user(conn) do
    with user_id when not is_nil(user_id) <- conn.private[__MODULE__],
         user    when not is_nil(user)    <- Repo.get(User, user_id)
    do
      user
    else
      _ -> nil
    end
  end

  def header, do: Application.get_env(:bibliotheca, :auth_header) |> String.downcase()
end