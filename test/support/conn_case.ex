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

  @user %Bibliotheca.User{id: 1,
                          email: "test@example.com",
                          password_digest: "hogehogefufgafuga",
                          auth_code: "ADMIN",
                          inserted_at: ~N[2015-04-01 12:00:00],
                          updated_at: ~N[2015-04-01 12:00:00]}

  def get_user(), do: @user

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

      @user Bibliotheca.ConnCase.get_user()

      defp jsonise(data), do:
        data |> Poison.encode!() |> Poison.decode!()
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Bibliotheca.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Bibliotheca.Repo, {:shared, self()})
    end

    require Phoenix.ConnTest

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("accept", "application/json")

    header = Application.get_env :bibliotheca, :auth_header
    Bibliotheca.Repo.insert! @user

    token = Bibliotheca.Auth.HMAC.create_token()

    Bibliotheca.Auth.Token.update_token @user, token

    {:ok, conn: Plug.Conn.put_req_header(conn, header, token)}
  end
end
