defmodule Bibliotheca.Plugs.Authorization do
  import Plug.Conn

  def authorize(conn, [level]) do
    case {level, conn.assigns[:current_user].auth_code} do
      {:admin, "ADMIN"} -> conn
      {:admin, _} -> reject(conn)
      {_, _} -> conn
    end
  end

  defp reject(conn), do: conn |> send_resp(403, "Forbidden") |> halt()
end