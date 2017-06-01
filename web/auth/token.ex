defmodule Bibliotheca.Auth.Token do

  def init, do:
    Agent.start_link fn -> %{} end, name: __MODULE__

  def lookup_user_id(token), do:
    Agent.get __MODULE__, fn map ->
      Enum.find(map, fn {_, ^token} -> true; _ -> false end)
      |> case do
        {user_id, _} -> user_id
        nil          -> nil
      end
    end

  def lookup_token(user_id), do:
    Agent.get __MODULE__, &Map.get(&1, user_id)

  def update_token(user_id, token), do:
    Agent.update __MODULE__, &Map.put(&1, user_id, token)

  def delete_token(user_id), do:
    Agent.update __MODULE__, &Map.delete(&1, user_id)

  def create_token(), do:
    :crypto.strong_rand_bytes(32)
    |> Base.encode64
    |> binary_part(0, 32)
end