defmodule Bibliotheca.Plugs.Authorization do
  import Plug.Conn
  import Bibliotheca.Plugs.Authentication, only: [current_user: 1]

  def authorize(conn, [level]) do
    case {level, current_user(conn).auth_code} do
      {:admin, "ADMIN"} -> conn
      {:admin, _} -> reject(conn)
      _ -> conn
    end
  end

  defp reject(conn), do: conn |> send_resp(403, "Forbidden") |> halt()
end