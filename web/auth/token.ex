defmodule Bibliotheca.Auth.Token do
  def init, do:
    Agent.start_link(fn -> %{} end, name: __MODULE__)

  def lookup_user(token), do:
    Agent.get(__MODULE__, fn map ->
      (for {_, {_, ^token}} = data <- map, do: data)
      |> case do
        [{_, {user, _}}] -> user
        [] -> nil
      end
    end)

  def lookup_token(user_id) do
    Agent.get(__MODULE__, &Map.get(&1, user_id))
    |> case do
      {_, token} -> token
      nil -> nil
    end
  end

  def update_token(user, token), do:
    Agent.update(__MODULE__, &Map.put(&1, user.id, {user, token}))

  def delete_token(user_id), do:
    Agent.update(__MODULE__, &Map.delete(&1, user_id))

  def create_token(), do:
    :crypto.strong_rand_bytes(32)
    |> Base.encode64
    |> binary_part(0, 32)
end