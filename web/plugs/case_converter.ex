defmodule Bibliotheca.Plugs.CaseConverter do
  @moduledoc """
  connのparamsの、camelCaseのキーの値をsnale_caseでも参照できるようにする。
  """

  def conv_case(conn, _), do: %{conn | params: conv_map conn.params}

  defp conv_map(map) do
    map
    |> Map.keys
    |> Enum.reduce(map, fn key, params ->
      case {Macro.underscore(key), params[key]} do
        {^key, value} when is_map value    -> %{params | key => conv_map value}
        {^key, _}                          -> params
        {new_key, value} when is_map value -> put_in params[new_key], conv_map value
        {new_key, value}                   -> put_in params[new_key], value
      end
    end)
  end
end