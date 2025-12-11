defmodule LiveReactIslands.LiveView do
  defmacro __using__(opts) do
    global_keys = Keyword.get(opts, :globals, [])

    quote do
      import Phoenix.Component, except: [assign: 2, assign: 3]

      @global_keys unquote(global_keys)

      def handle_event("get_globals", _params, socket) do
        globals =
          @global_keys
          |> Enum.map(fn key -> {key, Process.get({:global, key})} end)
          |> Enum.filter(fn {_key, value} -> value != nil end)
          |> Map.new()

        {:reply, globals, socket}
      end

      # Override assign to handle globals implicitly
      def assign(socket, key, value) when key in @global_keys do
        Process.put({:global, key}, value)
        socket = Phoenix.Component.assign(socket, key, value)
        Phoenix.LiveView.push_event(socket, "update_globals", %{key => value})
      end

      def assign(socket, key, value) do
        Phoenix.Component.assign(socket, key, value)
      end

      def assign(socket, assigns) when is_map(assigns) do
        Enum.reduce(assigns, socket, fn {key, value}, acc ->
          assign(acc, key, value)
        end)
      end

      def assign(socket, assigns) when is_list(assigns) do
        assigns_map = Map.new(assigns)
        assign(socket, assigns_map)
      end
    end
  end
end
