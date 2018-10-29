defmodule JaResource.Delete do
  import Plug.Conn

  @moduledoc """
  Defines a behaviour for deleting a resource and the function to execute it.

  It relies on (and uses):

    * JaResource.Repo
    * JaResource.Record

  When used JaResource.Delete defines the `delete/2` action suitable for
  handling json-api requests.

  To customize the behaviour of the update action the following callbacks can
  be implemented:

    * handle_delete/2
    * JaResource.Record.record/2
    * JaResource.Repo.repo/0

  """

  @doc """
  Returns an unpersisted changeset or persisted model representing the newly updated model.

  Receives the conn and the record as found by `record/2`.

  Default implementation returns the results of calling `Repo.delete(record)`.

  Example custom implementation:

      def handle_delete(conn, record) do
        case conn.assigns[:user] do
          %{is_admin: true} -> super(conn, record)
          _                 -> send_resp(conn, 401, "nope")
        end
      end

  """
  @callback handle_delete(Plug.Conn.t, JaResource.record) :: Plug.Conn.t | JaResource.record | nil

  defmacro __using__(_) do
    quote do
      use JaResource.Repo
      use JaResource.Record
      @behaviour JaResource.Delete

      def handle_invalid_delete(conn, errors) do
        import Plug.Conn
        conn
        |> put_status(:unprocessable_entity)
        |> Phoenix.Controller.render(:errors, data: errors)
      end

      def handle_delete(conn, nil), do: nil
      def handle_delete(conn, model) do
        model
        |> __MODULE__.model.changeset(%{})
        |> __MODULE__.repo().delete
      end

      defoverridable [handle_delete: 2]
    end
  end

  @doc """
  Execute the delete action on a given module implementing Delete behaviour and conn.
  """
  def call(controller, conn) do
    model = controller.record(conn, conn.params["id"])

    controller.handle_authorize(model, conn)

    conn
    |> controller.handle_delete(model)
    |> JaResource.Delete.respond(conn, controller)
  end

  @doc false
  def respond(nil, conn, _controller), do: not_found(conn)
  def respond(%Plug.Conn{} = conn, _old_conn, _controller), do: conn
  def respond(:ok, conn, _controller), do: deleted(conn)
  def respond({:ok, _model}, conn, _controller), do: deleted(conn)
  def respond({:errors, errors}, conn, _controller), do: invalid(conn, errors)
  def respond({:error, errors}, conn, _controller), do: invalid(conn, errors)
  # Do not quietly handle unknown cases
  #def respond(_model, conn, _controller), do: deleted(conn)

  defp not_found(conn) do
    conn
    |> send_resp(:not_found, "")
  end

  defp deleted(conn) do
    conn
    |> send_resp(:no_content, "")
  end

  defp invalid(conn, errors) do
    conn
    |> put_status(:unprocessable_entity)
    |> Phoenix.Controller.render(:errors, data: errors)
  end
end
