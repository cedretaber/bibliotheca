use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bibliotheca, Bibliotheca.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :bibliotheca, Bibliotheca.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "bibliotheca_test",
  hostname: "127.0.0.1",
  pool: Ecto.Adapters.SQL.Sandbox
