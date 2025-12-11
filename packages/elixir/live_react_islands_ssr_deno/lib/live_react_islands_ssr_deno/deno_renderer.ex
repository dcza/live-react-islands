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

  @impl true
  def preload_component(component_name) do
    GenServer.cast(__MODULE__, {:preload_component, component_name})
  end

  @impl true
  def clear_cache do
    GenServer.call(__MODULE__, :clear_cache)
  end

  @impl true
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl true
  def init(opts) do
    main_module_path = Keyword.fetch!(opts, :main_module_path)

    # Initialize DenoRider instance
    case DenoRider.start(main_module_path: main_module_path) do
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
      SSR_MODULE.renderSSRIslandStatic(
        #{Jason.encode!(component_name)},
        #{Jason.encode!(id)},
        #{Jason.encode!(props)},
        #{Jason.encode!(global_state)}
      );
    """

    case DenoRider.eval(render_script, pid: state.deno_instance) do
      {:ok, result} ->
        {:reply, {:ok, result}, state}

      {:error, reason} ->
        Logger.error("SSR render failed for #{component_name}: #{inspect(reason)}")
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

    Logger.info("DenoRenderer terminated: #{inspect(reason)}")
    :ok
  end
end
