defmodule LiveReactIslands.Component do
  @type ssr_strategy :: :none | :overwrite | :hydrate_root

  defmacro __using__(opts) do
    component_name =
      Keyword.get(opts, :component) ||
        raise ArgumentError,
              "LiveReactIsland requires `component` to be set to a valid React Island component."

    prop_defs = Keyword.get(opts, :props, quote(do: %{}))
    ssr_strategy = Keyword.get(opts, :ssr_strategy, :none)
    global_keys = Keyword.get(opts, :globals, [])

    quote do
      use Phoenix.LiveComponent

      @ssr_strategy unquote(ssr_strategy)

      # Dialyzer will warn about the SSR check in modules where ssr_strategy is :none,
      # but this is intentional - the check is compiled differently for each module
      @dialyzer {:no_match, render: 1}

      @impl true
      def render(assigns) do
        prop_defs = unquote(prop_defs)
        component_name = unquote(component_name)
        global_keys = unquote(global_keys)

        props =
          Enum.reduce(prop_defs, %{}, fn {k, v}, acc ->
            Map.put(acc, k, assigns[k] || v)
          end)

        globals =
          Enum.reduce(global_keys, %{}, fn k, acc ->
            Map.put(acc, k, Process.get({:global, k}))
          end)

        {:ok, staticHTML} =
          if @ssr_strategy == :overwrite do
            case Application.get_env(:live_react_islands, :ssr_renderer) do
              nil ->
                raise """
                SSR strategy is :overwrite but no :ssr_renderer configured.

                Add to your config/config.exs:

                    config :live_react_islands,
                      ssr_renderer: LiveReactIslands.SSR.DenoRenderer
                """

              renderer_module ->
                renderer_module.render_component(
                  component_name,
                  assigns.id,
                  props,
                  globals
                )
            end
          else
            {:ok, "<!-- React renders here -->"}
          end

        %Phoenix.LiveView.Rendered{
          static: [
            """
            <div id="#{assigns.id}" phx-hook="LiveReactIslands" phx-update="ignore" data-comp="#{component_name}" data-ssr="#{@ssr_strategy}">
              #{staticHTML}
            </div>
            """
          ],
          dynamic: fn _ -> [] end,
          fingerprint: assigns.id,
          root: true
        }
      end

      @impl true
      def update(assigns, socket) do
        prop_defs = unquote(prop_defs)

        case socket.assigns do
          %{__external_owned: external_owned, __internal_owned: internal_owned} ->
            socket =
              Enum.reduce(assigns, socket, fn {key, value}, acc ->
                cond do
                  key in [:id, :globals, :__external_owned, :__internal_owned] ->
                    acc

                  String.starts_with?(to_string(key), "init_") ->
                    acc

                  socket.assigns[key] == value ->
                    acc

                  MapSet.member?(external_owned, key) ->
                    {:ok, changed_socket} =
                      handle_assign(acc, key, value, allowed_to_push: true)

                    changed_socket

                  MapSet.member?(internal_owned, key) ->
                    new_external_owned = MapSet.put(external_owned, key)
                    new_internal_owned = MapSet.delete(internal_owned, key)

                    acc
                    |> assign(:__external_owned, new_external_owned)
                    |> assign(:__internal_owned, new_internal_owned)
                    |> then(fn socket ->
                      {:ok, changed_socket} =
                        handle_assign(socket, key, value, allowed_to_push: true)

                      changed_socket
                    end)

                  true ->
                    {:ok, changed_socket} = handle_assign(acc, key, value)
                    changed_socket
                end
              end)

            {:ok, socket}

          _ ->
            # Initial mount - initialize ownership tracking
            socket =
              socket
              |> assign(assigns)
              |> assign(:__external_owned, MapSet.new())
              # Start with all props internal
              |> assign(:__internal_owned, MapSet.new(Map.keys(prop_defs)))

            # Process all assigns first
            socket =
              Enum.reduce(assigns, socket, fn {key, value}, acc ->
                cond do
                  key in [:id, :globals, :__external_owned, :__internal_owned] ->
                    acc

                  # Handle init_* props - set value but keep internal ownership
                  String.starts_with?(to_string(key), "init_") ->
                    prop_key_string = String.replace_leading(to_string(key), "init_", "")

                    prop_key =
                      try do
                        String.to_existing_atom(prop_key_string)
                      rescue
                        ArgumentError -> nil
                      end

                    if Map.has_key?(prop_defs, prop_key) do
                      {:ok, changed_socket} = handle_assign(acc, prop_key, value)
                      changed_socket
                    else
                      raise ArgumentError,
                            "Unknown init prop `#{key}` - `#{prop_key_string}` is not defined in props"
                    end

                  # Client prop - transfer to external ownership
                  Map.has_key?(prop_defs, key) ->
                    external_owned = MapSet.put(acc.assigns.__external_owned, key)
                    internal_owned = MapSet.delete(acc.assigns.__internal_owned, key)

                    acc =
                      acc
                      |> assign(:__external_owned, external_owned)
                      |> assign(:__internal_owned, internal_owned)

                    {:ok, changed_socket} = handle_assign(acc, key, value, allowed_to_push: true)
                    changed_socket

                  true ->
                    {:ok, changed_socket} = handle_assign(acc, key, value)
                    changed_socket
                end
              end)

            # Assign unassigned props to default values
            socket =
              Enum.reduce(prop_defs, socket, fn {prop_key, default_value}, acc ->
                init_key =
                  try do
                    String.to_existing_atom("init_#{prop_key}")
                  rescue
                    ArgumentError -> nil
                  end

                cond do
                  # Already processed as regular prop
                  Map.has_key?(assigns, prop_key) ->
                    acc

                  # Already processed as init_* prop
                  init_key && Map.has_key?(assigns, init_key) ->
                    acc

                  true ->
                    {:ok, changed_socket} = handle_assign(acc, prop_key, default_value)
                    changed_socket
                end
              end)

            {:ok, socket}
        end
      end

      defoverridable update: 2

      defp update_prop(socket, key, fun, opts \\ [])

      defp update_prop(socket, key, fun, opts) when is_function(fun, 1) do
        current =
          case Map.fetch(socket.assigns, key) do
            {:ok, value} -> value
            :error -> nil
          end

        update_prop(socket, key, fun.(current), opts)
      end

      defp update_prop(socket, attr, value, opts) do
        internal_owned = Map.get(socket.assigns, :__internal_owned, MapSet.new())
        allowed_to_push = Keyword.get(opts, :allowed_to_push, false)

        if allowed_to_push or MapSet.member?(internal_owned, attr) do
          socket
          |> assign(attr, value)
          |> push_event("p", %{attr => value, id: socket.assigns.id})
        else
          raise ArgumentError, "Cannot modify undefined or externally owned prop `#{attr}`"
        end
      end

      defp handle_assign(socket, key, value, opts \\ []) do
        prop_defs = unquote(prop_defs)

        if Map.has_key?(prop_defs, key) do
          {:ok, update_prop(socket, key, value, opts)}
        else
          raise ArgumentError, """
          Unknown prop `#{key}` for this component.
          Only props defined in the props map can be assigned.
          Define custom handle_assign/3 to handle server-only data.
          """
        end
      end

      defoverridable handle_assign: 4
    end
  end
end
