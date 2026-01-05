defmodule LiveReactIslands.Component do
  @type ssr_strategy :: :none | :overwrite | :hydrate_root

  @doc false
  def get_or_create_island_index(island_id) do
    mappings = Process.get(:__island_mappings, %{})

    case Map.fetch(mappings, island_id) do
      {:ok, idx} ->
        idx

      :error ->
        next_index = Process.get(:__next_island_index, 0)
        Process.put(:__island_mappings, Map.put(mappings, island_id, next_index))
        Process.put(:__next_island_index, next_index + 1)
        next_index
    end
  end

  defmacro __using__(opts) do
    component_name =
      Keyword.get(opts, :component) ||
        raise ArgumentError,
              "LiveReactIsland requires `component` to be set to a valid React Island component."

    prop_defs = Keyword.get(opts, :props, quote(do: %{}))
    ssr_strategy = Keyword.get(opts, :ssr_strategy, :none)
    global_keys = Keyword.get(opts, :globals, [])

    # SSR cache is opt-in per component (defense in depth against potential bugs)
    cache_opts =
      case Keyword.get(opts, :ssr_cache, false) do
        true -> []
        opts when is_list(opts) -> opts
        _ -> nil
      end

    quote do
      use Phoenix.LiveComponent

      @ssr_strategy unquote(ssr_strategy)
      @cache_opts unquote(cache_opts)

      # Dialyzer will warn about the SSR check in modules where ssr_strategy is :none,
      # but this is intentional - the check is compiled differently for each module
      @dialyzer {:no_match, render: 1}

      @impl true
      def render(assigns) do
        prop_defs = unquote(prop_defs)
        component_name = unquote(component_name)
        global_keys = unquote(global_keys)
        island_index = LiveReactIslands.Component.get_or_create_island_index(assigns.id)

        # Parse global keys to determine which are optional (end with ?)
        parsed_globals =
          Enum.map(global_keys, fn key ->
            key_string = Atom.to_string(key)

            if String.ends_with?(key_string, "?") do
              clean_key =
                key_string
                |> String.trim_trailing("?")
                |> String.to_atom()

              {clean_key, true}
            else
              {key, false}
            end
          end)

        # Build available globals list (only include globals that exist)
        available_globals =
          Enum.filter(parsed_globals, fn {key, optional?} ->
            case Process.get({:global, key}, :__not_found__) do
              :__not_found__ ->
                if optional? do
                  false
                else
                  raise ArgumentError, """
                  Island component requested global :#{key} but it's not available.
                  Make sure the parent LiveView declares: use LiveReactIslands.LiveView, expose_globals: [:#{key}]
                  Or make it optional by adding a '?' suffix: globals: [:#{key}?]
                  """
                end

              _value ->
                true
            end
          end)

        # Build schema with ordered prop and global names
        prop_names = Enum.map(prop_defs, fn {k, _v} -> Atom.to_string(k) end)
        global_names = Enum.map(available_globals, fn {k, _opt} -> Atom.to_string(k) end)
        schema = %{p: prop_names, g: global_names, i: island_index}
        schema_json = Jason.encode!(schema)

        # Build props map for SSR (uses keys)
        props =
          Enum.reduce(prop_defs, %{}, fn
            {k, {:stream, opts}}, acc ->
              default = Keyword.get(opts, :default, [])
              initial = assigns[k] || default
              Map.put(acc, k, initial)

            {k, v}, acc ->
              Map.put(acc, k, assigns[k] || v)
          end)

        # Build props array (ordered by prop_defs, streams encoded as compact handles)
        props_array =
          prop_defs
          |> Enum.with_index()
          |> Enum.map(fn
            {{k, {:stream, opts}}, idx} ->
              default = Keyword.get(opts, :default, [])
              initial = assigns[k] || default
              %{__s: idx, i: initial}

            {{k, v}, _idx} ->
              assigns[k] || v
          end)

        props_json = Jason.encode!(props_array)

        version = Process.get({:global, :__version}, 0)

        # Build globals array (ordered by schema, only available globals)
        globals_array =
          Enum.map(available_globals, fn {k, _opt} ->
            Process.get({:global, k})
          end)

        globals_json = Jason.encode!(globals_array)

        # Build globals map for SSR (only available globals + version)
        globals =
          available_globals
          |> Enum.reduce(%{}, fn {k, _opt}, acc ->
            Map.put(acc, k, Process.get({:global, k}))
          end)
          |> Map.put(:__version, version)

        staticHTML =
          if @ssr_strategy == :none do
            "<!-- React renders here -->"
          else
            case Application.get_env(:live_react_islands, :ssr_renderer) do
              nil ->
                raise """
                SSR strategy is :overwrite or :hydrate_root but no :ssr_renderer configured.

                Add to your config/dev.exs:

                    config :live_react_islands,
                      ssr_renderer: LiveReactIslands.SSR.ViteRenderer

                Or for config/prod.exs:

                    config :live_react_islands,
                      ssr_renderer: LiveReactIslands.SSR.DenoRenderer
                """

              renderer_module ->
                # Check if SSR caching is configured globally
                cache_module = Application.get_env(:live_react_islands, :ssr_cache)

                # Merge component cache config with runtime overrides
                component_cache_opts = @cache_opts
                runtime_cache_opts = Map.get(assigns, :ssr_cache_opts, [])

                cache_opts =
                  if component_cache_opts do
                    Keyword.merge(component_cache_opts, runtime_cache_opts)
                  else
                    runtime_cache_opts
                  end

                # Determine if user wants caching (component opted in or runtime opts provided)
                wants_cache = is_list(component_cache_opts) or runtime_cache_opts != []

                # Determine if caching should be used (wants cache AND cache module configured)
                use_cache = cache_module && wants_cache

                # Warn if cache requested but no cache module configured
                if wants_cache and is_nil(cache_module) do
                  require Logger

                  Logger.warning(
                    "Island '#{component_name}' has caching enabled but :ssr_cache is not configured. " <>
                      "Caching will be skipped. Configure :ssr_cache in config.exs to enable caching."
                  )
                end

                # Use cache only if component opted in AND cache module is configured
                result =
                  if use_cache do
                    # Set default id_in_key if not specified
                    cache_opts_with_defaults = Keyword.put_new(cache_opts, :id_in_key, false)

                    # Shell caching: use ssr_props/ssr_globals for rendering, but cache based on real data
                    ssr_props = Keyword.get(cache_opts_with_defaults, :ssr_props, props)
                    ssr_globals = Keyword.get(cache_opts_with_defaults, :ssr_globals, globals)

                    cache_module.get_or_render(
                      component_name,
                      assigns.id,
                      ssr_props,
                      ssr_globals,
                      @ssr_strategy,
                      renderer_module,
                      cache_opts_with_defaults
                    )
                  else
                    # No caching - call renderer directly
                    renderer_module.render_component(
                      component_name,
                      assigns.id,
                      props,
                      globals,
                      @ssr_strategy
                    )
                  end

                case result do
                  {:ok, html} ->
                    html

                  {:error, reason} ->
                    require Logger

                    Logger.warning(
                      "SSR failed for #{component_name}: #{inspect(reason)} - falling back to client-side rendering"
                    )

                    "<!-- SSR failed, React will render client-side -->"
                end
            end
          end

        # Build data attributes
        base_attrs = """
        id="#{assigns.id}" \
        phx-hook="LiveReactIslands" \
        phx-update="ignore" \
        data-comp="#{component_name}" \
        data-ssr="#{@ssr_strategy}" \
        data-schema="#{Phoenix.HTML.Engine.html_escape(schema_json)}" \
        data-props="#{Phoenix.HTML.Engine.html_escape(props_json)}"
        """

        # Add data-globals and data-globals-version only for hydrate_root strategy
        attrs =
          if @ssr_strategy == :hydrate_root do
            base_attrs <>
              " data-globals=\"#{Phoenix.HTML.Engine.html_escape(globals_json)}\"" <>
              " data-globals-version=\"#{version}\""
          else
            base_attrs
          end

        %Phoenix.LiveView.Rendered{
          static: [
            """
            <div #{attrs}>#{staticHTML}</div>
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
            # Store prop schema for indexed updates
            prop_schema = Enum.map(prop_defs, fn {k, _v} -> k end)
            island_index = LiveReactIslands.Component.get_or_create_island_index(assigns.id)

            regular_prop_keys =
              prop_defs
              |> Enum.reject(fn {_k, v} -> match?({:stream, _}, v) end)
              |> Enum.map(fn {k, _} -> k end)

            socket =
              socket
              |> assign(assigns)
              |> assign(:__external_owned, MapSet.new())
              |> assign(:__internal_owned, MapSet.new(regular_prop_keys))
              |> assign(:__prop_schema, prop_schema)
              |> assign(:__island_index, island_index)

            # Process all assigns first
            socket =
              Enum.reduce(assigns, socket, fn {key, value}, acc ->
                cond do
                  key in [:id, :globals, :__external_owned, :__internal_owned] ->
                    acc

                  # Skip stream props - they're not assignable via regular assigns
                  match?({:stream, _}, prop_defs[key]) ->
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

                    cond do
                      match?({:stream, _}, prop_defs[prop_key]) ->
                        raise ArgumentError,
                              "Cannot use init_#{prop_key} - streams don't support init_ props"

                      Map.has_key?(prop_defs, prop_key) ->
                        assign(acc, prop_key, value)

                      true ->
                        raise ArgumentError,
                              "Unknown init prop `#{key}` - `#{prop_key_string}` is not defined in props"
                    end

                  # Client prop - transfer to external ownership
                  Map.has_key?(prop_defs, key) ->
                    external_owned = MapSet.put(acc.assigns.__external_owned, key)
                    internal_owned = MapSet.delete(acc.assigns.__internal_owned, key)

                    acc
                    |> assign(:__external_owned, external_owned)
                    |> assign(:__internal_owned, internal_owned)
                    |> assign(key, value)

                  # Initial mount - no push, props already in data-props

                  true ->
                    {:ok, changed_socket} = handle_assign(acc, key, value)
                    changed_socket
                end
              end)

            # Assign unassigned props to default values
            socket =
              Enum.reduce(prop_defs, socket, fn
                # Stream props - extract default from {:stream, opts}
                {prop_key, {:stream, opts}}, acc ->
                  default = Keyword.get(opts, :default, [])
                  # Streams don't check assigns - always use default on mount
                  assign(acc, prop_key, default)

                # Regular props
                {prop_key, default_value}, acc ->
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
                      # Initial mount - just assign default, no push
                      assign(acc, prop_key, default_value)
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
          # Find the index of this prop in the schema
          prop_schema = Map.get(socket.assigns, :__prop_schema, [])
          prop_index = Enum.find_index(prop_schema, &(&1 == attr))
          island_index = Map.get(socket.assigns, :__island_index)

          socket
          |> assign(attr, value)
          |> push_event("lri-p", %{prop_index => value, i: island_index})
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

      # Stream helper functions

      @doc """
      Insert a new entry into a stream.
      The entry must have an `id` field for updates/deletes to work.
      """
      defp stream_insert(socket, stream_name, entry) do
        stream_event(socket, stream_name, "i", entry)
      end

      @doc """
      Update an existing entry in a stream by its id.
      The entry must have an `id` field matching an existing entry.
      """
      defp stream_update(socket, stream_name, entry) do
        stream_event(socket, stream_name, "u", entry)
      end

      @doc """
      Delete an entry from a stream by its id.
      Pass just the id value, not the full entry.
      """
      defp stream_delete(socket, stream_name, id) do
        stream_event(socket, stream_name, "d", id)
      end

      @doc """
      Reset a stream, clearing all entries.
      """
      defp stream_reset(socket, stream_name) do
        stream_event(socket, stream_name, "r", nil)
      end

      defp stream_event(socket, stream_name, action, data) do
        prop_defs = unquote(prop_defs)

        unless match?({:stream, _}, prop_defs[stream_name]) do
          raise ArgumentError, """
          Unknown stream `#{stream_name}` for this component.
          Only props defined as {:stream, opts} can be used with stream_* functions.
          """
        end

        prop_schema = Map.get(socket.assigns, :__prop_schema, [])
        prop_index = Enum.find_index(prop_schema, &(&1 == stream_name))
        island_index = Map.get(socket.assigns, :__island_index)

        payload = %{s: prop_index, a: action, d: data, i: island_index}
        push_event(socket, "lri-s", payload)
      end
    end
  end
end
