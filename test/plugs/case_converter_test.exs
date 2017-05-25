defmodule Bibliotheca.Plugs.CaseConverterTest do
  use Bibliotheca.ConnCase

  import Bibliotheca.Plugs.CaseConverter

  describe "conv_case" do
    test "convert camelCase key to snake_case.", %{conn: conn} do
      url = "http://example.com/book1.png"
      at = "2010-06-01"
      conn = %{conn | params: %{"book" => %{"title" => "book1", "imageUrl" => url, "publishedAt" => at}}}
        |> conv_case(nil)

      assert conn.params ==
        %{"book" => %{"title" => "book1", "image_url" => url, "imageUrl" => url, "published_at" => at, "publishedAt" => at}}
    end

    test "convert no camelCase params.", %{conn: conn} do
      params = %{"user" => %{"password" => "hogehoge", "email" => "test@example.com"}}
      conn = %{conn | params: params}
        |> conv_case(nil)

      assert conn.params == params
    end

    test "nested param.", %{conn: conn} do
      params = %{"hogeFuga" => %{"fooBar" => 42}}
      conn = %{conn | params: params}
        |> conv_case(nil)

      assert conn.params ==
        %{"hogeFuga" => %{"fooBar" => 42}, "hoge_fuga" => %{"fooBar" => 42, "foo_bar" => 42}}
    end
  end
end