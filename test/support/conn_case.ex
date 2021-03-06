defmodule Bibliotheca.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  @password "hogehogefufgafuga"
  @user %Bibliotheca.User{
    id: 1,
    email: "test@example.com",
    password_digest: Bibliotheca.Auth.HMAC.hexdigest(@password),
    auth_code: "ADMIN",
    inserted_at: ~N[2015-04-01 12:00:00],
    updated_at: ~N[2015-04-01 12:00:00]
  }

  def get_password, do: @password
  def get_user, do: @user

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      alias Bibliotheca.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import Bibliotheca.Router.Helpers

      # The default endpoint for testing
      @endpoint Bibliotheca.Endpoint

      @password Bibliotheca.ConnCase.get_password()
      @user Bibliotheca.ConnCase.get_user()

      defp jsonise(data), do: data |> Poison.encode!() |> Poison.decode!()

      defp login_user(conn, user) do
        conn = Guardian.Plug.api_sign_in(conn, user)

        header = Bibliotheca.Plugs.Authentication.header()
        realm = Bibliotheca.Plugs.Authentication.realm()
        jwt = Guardian.Plug.current_token(conn)

        Plug.Conn.put_resp_header(conn, header, "#{realm} #{jwt}")
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Bibliotheca.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Bibliotheca.Repo, {:shared, self()})
    end

    Bibliotheca.Repo.insert!(@user)
    Ecto.Adapters.SQL.query!(Bibliotheca.Repo, "SELECT setval('users_id_seq', 99)")

    conn =
      Phoenix.ConnTest.build_conn()
      |> Guardian.Plug.api_sign_in(@user)

    header = Bibliotheca.Plugs.Authentication.header()
    realm = Bibliotheca.Plugs.Authentication.realm()
    jwt = Guardian.Plug.current_token(conn)

    conn =
      conn
      |> Plug.Conn.put_req_header("accept", "application/json")
      |> Plug.Conn.put_req_header(header, "#{realm} #{jwt}")

    {:ok, conn: conn}
  end
end
