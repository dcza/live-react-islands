defmodule LiveReactIslands.SSR.Renderer do
  @moduledoc """
  Behaviour for SSR renderer implementations.

  Implementations should handle rendering React components to HTML strings.
  This allows for different SSR backends (Deno, Node, Bun, etc.)
  """

  @doc """
  Renders a React component to an HTML string.

  ## Parameters
  - component_name: String name of the React component
  - id: Unique identifier for this island instance
  - props: Map of props to pass to the component
  - global_state: Map of global state shared across islands
  - strategy: SSR strategy (:overwrite or :hydrate_root)

  ## Returns
  - {:ok, html_string} on success
  - {:error, reason} on failure
  """
  @callback render_component(
              component_name :: String.t(),
              id :: String.t(),
              props :: map(),
              global_state :: map(),
              strategy :: atom()
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
