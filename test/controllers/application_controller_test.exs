defmodule Bibliotheca.ApplicationControllerTest do
  use Bibliotheca.ConnCase, async: true

  describe "ping/2" do
    test "ping", %{conn: conn} do
      conn = get(conn, "/api/ping")

      assert conn.status == 204
    end

    test "ping when not logged in." do
      conn = get(build_conn(), "/api/ping")

      assert conn.status == 204
    end
  end
end
