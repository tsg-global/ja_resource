defmodule JaResource.Authorize do
  @moduledoc """
  Provides the `handle_authorize/2` callback used to authorize the resource.

  This behaviour is used by all JaResource actions.
  """

  @doc """
  Called before all the actions with the model. Useful for authorizing.
  """
  @callback handle_authorize(JaResource.record, Plug.Conn.t) :: any

  defmacro __using__(_) do
    quote do
      @behaviour JaResource.Authorize

      def handle_authorize(model, _conn), do: model

      defoverridable [handle_authorize: 2]
    end
  end
end
