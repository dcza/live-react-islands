defmodule LiveReactIslands.SSR.Renderer do
  @moduledoc """
  Behaviour for SSR renderer implementations.

  Implementations should handle rendering React components to HTML strings.
  This allows for different SSR backends (Deno, Node, Bun, etc.)

  ## Example Implementation

      defmodule MyApp.DenoRenderer do
        @behaviour LiveReactIslands.SSR.Renderer
        use GenServer

        def start_link(opts) do
          GenServer.start_link(__MODULE__, opts, name: __MODULE__)
        end

        @impl true
        def render_component(component_name, id, props, global_state) do
          GenServer.call(__MODULE__, {:render, component_name, id, props, global_state})
        end

        # ... GenServer callbacks
      end
  """

  @doc """
  Renders a React component to an HTML string.

  ## Parameters
  - component_name: String name of the React component
  - id: Unique identifier for this island instance
  - props: Map of props to pass to the component
  - global_state: Map of global state shared across islands

  ## Returns
  - {:ok, html_string} on success
  - {:error, reason} on failure
  """
  @callback render_component(
              component_name :: String.t(),
              id :: String.t(),
              props :: map(),
              global_state :: map()
            ) :: {:ok, String.t()} | {:error, term()}

  @doc """
  Optionally preload a component for faster rendering.
  Default implementation does nothing.
  """
  @callback preload_component(component_name :: String.t()) :: :ok

  @doc """
  Clear any cached component data.
  """
  @callback clear_cache() :: :ok

  @doc """
  Get renderer statistics.
  """
  @callback get_stats() :: map()

  @optional_callbacks [preload_component: 1, clear_cache: 0, get_stats: 0]
end
