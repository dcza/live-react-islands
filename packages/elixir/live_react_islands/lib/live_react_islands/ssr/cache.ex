defmodule LiveReactIslands.SSR.Cache do
  @moduledoc """
  Behavior for SSR caching implementations.

  This behavior sits between `LiveReactIslands.Component` and SSR renderer modules,
  providing a caching layer to avoid re-rendering islands with identical props and globals.

  ## Usage

  Configure a cache module in your application config:

      config :live_react_islands,
        ssr_renderer: LiveReactIslands.SSR.ViteRenderer,
        ssr_cache: LiveReactIslands.SSR.ETSCache,
        cache_default_ttl: :timer.minutes(5)

  Caching is opt-in per component. Components must explicitly specify
  `ssr_cache: [...]` to enable caching.

  ## Cache Key Strategy

  Implementations should support configurable cache key behavior via `id_in_key` option:

  - `id_in_key: false` (default) - Hash of `{component_name, props, globals}` (excludes `id`, allows cache sharing across instances)
  - `id_in_key: true` - Hash of `{component_name, id, props, globals}` (per-instance caching)
  - `cache_key_fn` - Custom function `fn(name, id, props, globals, opts) -> terms_to_hash` for advanced use cases

  ## TTL Hierarchy

  TTL (time-to-live) can be specified at two levels (highest priority first):

  1. Component config - Configure per-component TTL via `ssr_cache: [ttl: ...]` on component
  2. Default - Global default TTL from `:cache_default_ttl` in application config

  ## Performance

  Implementations should optimize for cache hits:

  - Cache hits should avoid GenServer calls (direct ETS read recommended)
  - Cache misses should prevent duplicate renders (Winner/Waiter pattern recommended)
  - Thundering herd protection (atomic locking via `:ets.insert_new/2`)
  """

  @doc """
  Get cached render or render and cache.

  This is the main entry point for the cache. It should:

  1. Generate a cache key based on the cache key strategy
  2. Check if a valid (non-expired) cached result exists
  3. On cache hit: Return cached HTML immediately
  4. On cache miss: Render via `renderer_module.render_component/5` and cache result

  ## Parameters

  - `component_name` - Name of the React component (e.g., "Counter")
  - `id` - Unique instance ID of the island
  - `props` - Map of props to pass to the component
  - `globals` - Map of global state (includes `__version` key)
  - `strategy` - SSR strategy (`:overwrite` or `:hydrate_root`)
  - `renderer_module` - Module implementing `LiveReactIslands.SSR.Renderer` behavior
  - `opts` - Keyword list of options:
    - `:ttl` - Override TTL in milliseconds
    - `:id_in_key` - Include instance ID in cache key (boolean, default: false)
    - `:cache_key_fn` - Custom cache key function (advanced, overrides `id_in_key`)

  ## Returns

  - `{:ok, html}` - Successfully rendered or retrieved from cache
  - `{:error, reason}` - Rendering failed or cache error
  """
  @callback get_or_render(
              component_name :: String.t(),
              id :: String.t(),
              props :: map(),
              globals :: map(),
              ssr_strategy :: atom(),
              renderer_module :: module(),
              opts :: keyword()
            ) :: {:ok, String.t()} | {:error, term()}

  @doc """
  Clear all cached entries.

  This should remove all cached SSR results, forcing fresh renders on next request.

  ## Returns

  - `:ok` - Cache cleared successfully
  """
  @callback clear_cache() :: :ok

  @doc """
  Clear cached entries for a specific component.

  This should remove only cached results for the specified component name,
  leaving other components' cache intact.

  ## Parameters

  - `component_name` - Name of the component to clear (e.g., "Counter")

  ## Returns

  - `:ok` - Component cache cleared successfully

  ## Note

  Some implementations may choose to clear the entire cache if selective
  clearing is not supported or too expensive.
  """
  @callback clear_cache(component_name :: String.t()) :: :ok

  @doc """
  Get cache statistics.

  Returns a map containing cache metrics and information.

  ## Returns

  A map with at least:

  - `:size` - Number of cached entries
  - `:memory` - Memory usage in bytes (if available)
  - Additional implementation-specific metrics
  """
  @callback get_stats() :: map()
end
