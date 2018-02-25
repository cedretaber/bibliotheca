# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :bibliotheca,
  ecto_repos: [Bibliotheca.Repo],
  hmac_key: "vE2RQDJm/j61IxAgbDDRowm4Mc8U8WhARYYVuS0qkocABmdiJZoEIb+KNPeo6OEY",
  auth_header: "Authorization"

# Configures the endpoint
config :bibliotheca, Bibliotheca.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "DOHc2JpuB1KhpumkGM+E6/7YmDW2ET7UshTC3Z9YUO0/zyMUY2zsI9RnPmdH98p3",
  render_errors: [view: Bibliotheca.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Bibliotheca.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configures Guardian
config :guardian, Guardian,
  allowed_algos: ["HS512"],
  verify_module: Guardian.JWT,
  ttl: {1, :days},
  allowed_drift: 2000,
  verify_issuer: false,
  secret_key: "IQ/Wc/HdH6s3HbLbMx73LNvOOtiu3IJE1G8phH2Nqxu409txMe+z0Ttw/RlCmpcE",
  serializer: Bibliotheca.Auth.GuardianSerializer

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
