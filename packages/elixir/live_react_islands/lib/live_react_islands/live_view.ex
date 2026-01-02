defmodule LiveReactIslands.LiveView.Lifecycle do
  def on_mount(keys, _params, _session, socket) do
    Enum.each(keys, fn key ->
      Process.delete({:global, key})
    end)

    Process.put({:global, :__version}, 0)

    {:cont, socket}
  end
end

defmodule LiveReactIslands.LiveView do
  defmacro __using__(opts) do
    global_keys = Keyword.get(opts, :expose_globals, [])

    quote do
      import Phoenix.Component, except: [assign: 2, assign: 3]

      @global_keys unquote(global_keys)

      on_mount({LiveReactIslands.LiveView.Lifecycle, unquote(global_keys)})

      def handle_event("lri-g", _params, socket) do
        version = Process.get({:global, :__version}, 0)

        globals =
          @global_keys
          |> Enum.map(fn key -> {key, Process.get({:global, key})} end)
          |> Enum.filter(fn {_key, value} -> value != nil end)
          |> Map.new()
          |> Map.put(:__version, version)

        {:reply, globals, socket}
      end

      # Override assign to handle globals implicitly
      def assign(socket, key, value) when key in @global_keys do
        version = Process.get({:global, :__version}, 0) + 1
        Process.put({:global, :__version}, version)

        Process.put({:global, key}, value)
        socket = Phoenix.Component.assign(socket, key, value)
        Phoenix.LiveView.push_event(socket, "lri-g", %{key => value, :__version => version})
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
