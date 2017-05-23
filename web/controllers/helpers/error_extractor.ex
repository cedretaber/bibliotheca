defmodule Bibliotheca.Helpers.ErrorExtractor do
  def extract_errors(changeset), do:
    for {key, {message, details}} <- changeset.errors, do:
      %{ key => %{ message: message, details: (for {key, value} <- details, do: %{ key => value }) } }
end