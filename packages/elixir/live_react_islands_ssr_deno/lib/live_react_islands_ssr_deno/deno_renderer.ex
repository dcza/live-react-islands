defmodule LiveReactIslands.SSR.DenoRenderer do
  @moduledoc """
  Deno-based SSR renderer implementation using DenoRider.

  Implements the LiveReactIslands.SSR.Renderer behaviour to provide
  server-side rendering of React components using Deno.
  """
  @behaviour LiveReactIslands.SSR.Renderer
  use GenServer
  require Logger

  @default_timeout 5000
  @component_cache_ttl :timer.minutes(10)

  defstruct [:deno_instance, :component_cache, :cache_cleanup_timer]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def render_component(component_name, id, props, global_state) do
    GenServer.call(
      __MODULE__,
      {:render_component, component_name, id, props, global_state},
      @default_timeout
    )
  end

  def preload_component(component_name) do
    GenServer.cast(__MODULE__, {:preload_component, component_name})
  end

  def clear_cache do
    GenServer.call(__MODULE__, :clear_cache)
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl true
  def init(opts) do
    main_module_path = Keyword.fetch!(opts, :main_module_path)

    # Initialize DenoRider instance
    case DenoRider.start_link(main_module_path: main_module_path) do
      {:ok, deno_instance} ->
        # Setup React SSR environment

        state = %__MODULE__{
          deno_instance: deno_instance,
          component_cache: %{},
          cache_cleanup_timer: Process.send_after(self(), :cleanup_cache, @component_cache_ttl)
        }

        Logger.info("ReactSSRServer started successfully with module: #{main_module_path}")
        {:ok, state}

      {:error, reason} ->
        Logger.error("Failed to start DenoRider: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call({:render_component, component_name, id, props, global_state}, _from, state) do
    render_script = """
    renderSSRIslandStatic(
      #{Jason.encode!(component_name)},
      #{Jason.encode!(id)},
      #{Jason.encode!(props)},
      #{Jason.encode!(global_state)}
    )
    """

    case DenoRider.eval(render_script) do
      {:ok, result} ->
        {:reply, {:ok, result}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:clear_cache, _from, state) do
    new_state = %{state | component_cache: %{}}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      cache_size: map_size(state.component_cache),
      deno_instance: state.deno_instance != nil
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_info(:cleanup_cache, state) do
    # Simple cache cleanup - in production you might want more sophisticated LRU
    new_state = %{state | component_cache: %{}}
    timer = Process.send_after(self(), :cleanup_cache, @component_cache_ttl)
    {:noreply, %{new_state | cache_cleanup_timer: timer}}
  end

  @impl true
  def terminate(reason, state) do
    if state.cache_cleanup_timer do
      Process.cancel_timer(state.cache_cleanup_timer)
    end

    if state.deno_instance do
      DenoRider.stop()
    end

    Logger.info("ReactSSRServer terminated: #{inspect(reason)}")
    :ok
  end
end

# # lib/mpn_web_web/live_react_island.ex - Updated macro
# defmodule MPNWebWeb.LiveReactIsland do
#   defmacro __using__(opts) do
#     component_name =
#       Keyword.get(opts, :component) ||
#         raise ArgumentError,
#               "LiveReactIsland requires `component` to be set to a valid React Island component."

#     prop_defs = Keyword.get(opts, :props, quote(do: %{}))
#     ssr_strategy = Keyword.get(opts, :ssr_strategy, :none)

#     quote do
#       use Phoenix.LiveComponent
#       alias MPNWebWeb.ReactSSR.ReactSSRServer

#       defp validatePropKey!(key) do
#         if Map.has_key?(unquote(prop_defs), key) do
#           :ok
#         else
#           raise ArgumentError, "Unknown prop `#{key}` for this component."
#         end
#       end

#       defp assign_and_push(socket, attr, value) do
#         socket
#         |> assign(attr, value)
#         |> push_event("p", %{attr => value, id: socket.assigns.id})
#       end

#       defp update_prop(socket, key, fun) when is_function(fun, 1) do
#         validatePropKey!(key)
#         current = Map.fetch!(socket.assigns, key)
#         assign_and_push(socket, key, fun.(current))
#       end

#       defp update_prop(socket, key, value) do
#         validatePropKey!(key)
#         assign_and_push(socket, key, value)
#       end

#       defp render_ssr_content(assigns) do
#         component_name = unquote(component_name)
#         ssr_strategy = unquote(ssr_strategy)

#         case ssr_strategy do
#           :none ->
#             "<!-- React hydrates here -->"

#           :overwrite_ssr ->
#             # Extract only the props that are defined in prop_defs
#             prop_defs = unquote(prop_defs)

#             ssr_props =
#               prop_defs
#               |> Enum.into(%{}, fn {key, default_value} ->
#                 {key, Map.get(assigns, key, default_value)}
#               end)

#             case ReactSSRServer.render_component(component_name, ssr_props) do
#               {:ok, html} ->
#                 html

#               {:error, reason} ->
#                 require Logger
#                 Logger.warning("SSR failed for #{component_name}: #{inspect(reason)}")
#                 "<!-- SSR failed, React will hydrate -->"
#             end

#           :hydrated_root ->
#             # For future implementation - would need separate React roots per island
#             "<!-- Hydrated root not yet implemented -->"
#         end
#       end

#       @impl true
#       def render(assigns) do
#         component_name = unquote(component_name)
#         ssr_content = render_ssr_content(assigns)

#         %Phoenix.LiveView.Rendered{
#           static: [
#             """
#             <div id="#{assigns.id}" phx-hook="ReactIsland" phx-update="ignore" data-component="#{component_name}">
#               #{ssr_content}
#             </div>
#             """
#           ],
#           dynamic: fn _ -> [] end,
#           fingerprint: assigns.id,
#           root: true
#         }
#       end

#       @impl true
#       def update(assigns, socket) do
#         prop_defs = unquote(prop_defs)

#         case socket.assigns do
#           %{__ReactIslandInit: true} ->
#             changed_assigns =
#               assigns
#               |> Enum.reject(fn {key, value} ->
#                 socket.assigns[key] == value
#               end)
#               |> Map.new()

#             socket =
#               Enum.reduce(changed_assigns, socket, fn {key, value}, acc ->
#                 if function_exported?(__MODULE__, :handle_assign, 3) do
#                   {:ok, changed_socket} = apply(__MODULE__, :handle_assign, [acc, key, value])
#                   changed_socket
#                 else
#                   if Map.has_key?(prop_defs, key) do
#                     assign_and_push(acc, key, value)
#                   else
#                     raise ArgumentError, """
#                     Unknown prop `#{key}` for this component.
#                     Only pass props to the live_componenet that are mirrored in React.
#                     Use handle_assign/3 in the LiveReactIsland module to handle arbitrary assigns manually.
#                     """
#                   end
#                 end
#               end)

#             {:ok, socket}

#           _ ->
#             socket =
#               socket |> assign(assigns) |> assign(__ReactIslandInit: true)

#             socket =
#               Enum.reduce(prop_defs, socket, fn {k, v}, acc ->
#                 if function_exported?(__MODULE__, :handle_assign, 3) do
#                   if Map.has_key?(acc.assigns, k) do
#                     {:ok, changed_socket} =
#                       apply(__MODULE__, :handle_assign, [acc, k, acc.assigns[k]])

#                     changed_socket
#                   else
#                     socket = assign(acc, k, v)

#                     {:ok, changed_socket} =
#                       apply(__MODULE__, :handle_assign, [socket, k, v])

#                     changed_socket
#                   end
#                 else
#                   if Map.has_key?(acc.assigns, k) do
#                     push_event(acc, "p", %{k => acc.assigns[k], id: socket.assigns.id})
#                   else
#                     assign_and_push(acc, k, v)
#                   end
#                 end
#               end)

#             unknown_keys =
#               assigns
#               |> Map.keys()
#               |> Enum.reject(&Map.has_key?(prop_defs, &1))
#               |> Enum.reject(&(&1 in [:id, :__ReactIslandInit]))

#             socket =
#               Enum.reduce(unknown_keys, socket, fn key, acc ->
#                 if function_exported?(__MODULE__, :handle_assign, 3) do
#                   {:ok, changed_socket} =
#                     apply(__MODULE__, :handle_assign, [acc, key, assigns[key]])

#                   changed_socket
#                 else
#                   raise ArgumentError, """
#                   Unknown prop `#{key}` for this component.
#                   Only pass props to the live_componenet that are mirrored in React.
#                   Use handle_assign/3 in the LiveReactIsland module to handle arbitrary assigns manually.
#                   """
#                 end
#               end)

#             {:ok, socket}
#         end
#       end
#     end
#   end
# end
