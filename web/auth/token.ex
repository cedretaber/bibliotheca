defmodule Bibliotheca.Auth.Token do
  def init, do:
    Agent.start_link(fn -> %{} end, name: __MODULE__)

  def update_token(user, token), do:
    Agent.update(__MODULE__, &Map.put(&1, user.id, {user, token}))

  def lookup_user(token), do:
    Agent.get(__MODULE__, fn lst ->
      user_with_token =
        Enum.find lst, fn
          {_, {_, ^token}} -> true
          _ -> false
        end

      case user_with_token do
        {_, {user, _}} -> user
        nil -> nil
      end
    end)

  def delete_token(user_id), do:
    Agent.update(__MODULE__, &Map.delete(&1, user_id))
end