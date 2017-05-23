defmodule Bibliotheca.Auth.HMAC do
  def hexdigest(data), do:
    :crypto.hmac(:sha256, Application.get_env(:bibliotheca, :hmac_key), data)
    |> Base.encode16
end