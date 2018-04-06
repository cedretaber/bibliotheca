defmodule Bibliotheca.Auth.HMAC do
  # credo:disable-for-lines:3 Credo.Check.Refactor.PipeChainStart
  def hexdigest(data),
    do:
      :crypto.hmac(:sha256, Application.get_env(:bibliotheca, :hmac_key), data)
      |> Base.encode16()

  def verify_password(hashed, plain), do: Plug.Crypto.secure_compare(hashed, hexdigest(plain))
end
