defmodule Bibliotheca.Auth.HMAC do
  def hexdigest(data), do:
    :crypto.hmac(:sha256, Application.get_env(:bibliotheca, :hmac_key), data)
    |> Base.encode16

  def create_token(), do:
    :crypto.strong_rand_bytes(32)
    |> Base.encode64
    |> binary_part(0, 32)
end