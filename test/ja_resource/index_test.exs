defmodule JaResource.IndexTest do
  use ExUnit.Case
  use Plug.Test
  alias JaResource.Index

  defmodule DefaultController do
    use Phoenix.Controller
    use JaResource.Authorize
    use JaResource.Index
    def repo, do: JaResourceTest.Repo
    def model, do: JaResourceTest.Post
  end

  defmodule CustomController do
    use Phoenix.Controller
    use JaResource.Authorize
    use JaResource.Index
    def repo, do: JaResourceTest.Repo
    def handle_index(conn, _id), do: send_resp(conn, 401, "")
  end

  defmodule QueryErrorController do
    use Phoenix.Controller
    use JaResource.Authorize
    use JaResource.Index
    def repo, do: JaResourceTest.Repo
    def handle_index_query(_conn, _params),
      do: {:error, [details: "An error"]}
  end

  setup do
    JaResourceTest.Repo.reset
    JaResourceTest.Repo.insert(%JaResourceTest.Post{id: 1})
    JaResourceTest.Repo.insert(%JaResourceTest.Post{id: 2})
    :ok
  end

  test "default implementation returns all records" do
    conn = prep_conn(:get, "/posts/")
    response = Index.call(DefaultController, conn)
    assert response.status == 200

    # Note, not real json-api spec view
    json = Poison.decode!(response.resp_body, keys: :atoms!)
    assert [_, _] = json[:data]
  end

  test "custom implementation returns 401" do
    conn = prep_conn(:get, "/posts")
    response = Index.call(CustomController, conn)
    assert response.status == 401
  end

  test "query errors are handled correctly" do
    conn = prep_conn(:get, "/posts")
    response = Index.call(QueryErrorController, conn)
    json = Poison.decode!(response.resp_body, keys: :atoms!)
    assert json[:errors] == %{details: "An error"}
    assert response.status == 500
  end

  @tag :skip
  test "filtering adds conditional to query"
  @tag :skip
  test "sorting adds order statements to query"

  def prep_conn(method, path, params \\ %{}) do
    params = Map.merge(params, %{"_format" => "json"})
    conn(method, path, params)
      |> fetch_query_params
      |> Phoenix.Controller.put_view(JaResourceTest.PostView)
  end
end
