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

  defstruct [:deno_instance]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def render_component(component_name, id, props, global_state, strategy) do
    timeout = Application.get_env(:live_react_islands_ssr_deno, :timeout, @default_timeout)

    GenServer.call(
      __MODULE__,
      {:render_component, component_name, id, props, global_state, strategy},
      timeout
    )
  end

  @impl true
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl true
  def init(opts) do
    main_module_path = Keyword.fetch!(opts, :main_module_path)

    case DenoRider.start(main_module_path: main_module_path) do
      {:ok, deno_instance} ->
        state = %__MODULE__{deno_instance: deno_instance}
        Logger.info("ReactSSRServer started successfully with module: #{main_module_path}")
        {:ok, state}

      {:error, reason} ->
        Logger.error("Failed to start DenoRider: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call(
        {:render_component, component_name, id, props, global_state, strategy},
        _from,
        state
      ) do
    js_strategy =
      case strategy do
        :hydrate_root -> "hydrate_root"
        :overwrite -> "overwrite"
        _ -> "overwrite"
      end

    render_script = """
      SSR_MODULE.renderSSRIsland(
        #{Jason.encode!(component_name)},
        #{Jason.encode!(id)},
        #{Jason.encode!(props)},
        #{Jason.encode!(global_state)},
        #{Jason.encode!(js_strategy)}
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
  def handle_call(:get_stats, _from, state) do
    stats = %{deno_instance: state.deno_instance != nil}
    {:reply, stats, state}
  end

  @impl true
  def terminate(reason, state) do
    if state.deno_instance do
      DenoRider.stop()
    end

    Logger.info("DenoRenderer terminated: #{inspect(reason)}")
    :ok
  end
end
