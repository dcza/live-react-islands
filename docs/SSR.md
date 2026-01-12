# Server-Side Rendering (SSR)

SSR improves initial page load performance by rendering React components on the server. This guide covers setup, strategies, caching, and extensibility.

## SSR Entry Point

Create an SSR entry file that exposes your islands for server-side rendering. This must be bundled separately from your client code.

```javascript
// src/ssr.js
import { exposeSSR } from "@live-react-islands/core/ssr";
import islands from "./islands";

exposeSSR({ islands });
```

> **Important:** SSR code runs in a non-browser environment (Deno, Node). Avoid browser-only APIs (`window`, `document`, `localStorage`) in code that executes during render. Use `useEffect` for browser-only logic. See [React SSR guidelines](https://react.dev/reference/react-dom/server) for details.

## SSR Strategies

Configure SSR strategy per component:

```elixir
use LiveReactIslands.Component,
  component: "Counter",
  props: %{count: 0},
  ssr_strategy: :hydrate_root  # or :overwrite or :none (default)
```

| Strategy        | Shared Root | Best For                                                                 |
| --------------- | ----------- | ------------------------------------------------------------------------ |
| `:none`         | Yes         | Interactive components where initial render doesn't matter               |
| `:overwrite`    | Yes         | Most islands, especially when you need cross-island context (e.g., DnD)  |
| `:hydrate_root` | No          | Large islands where you want to avoid the overwrite flash                |

**How it works:**

- **`:none`** - No SSR. Client renders into an empty container.
- **`:overwrite`** - Server renders HTML, client replaces it. Islands render into a shared React root via portals, enabling shared context across islands.
- **`:hydrate_root`** - Server renders HTML, client hydrates in place. Each island gets its own React root (no shared context).

## Development Setup (Vite)

```javascript
// vite.config.js
import { liveReactIslandsSSR } from "@live-react-islands/vite-plugin-ssr";

export default {
  plugins: [liveReactIslandsSSR({ ssrEntry: "./src/ssr.js" })],
};
```

```elixir
# config/dev.exs
config :live_react_islands,
  ssr_renderer: LiveReactIslands.SSR.ViteRenderer

config :live_react_islands_ssr_vite,
  vite_url: "http://127.0.0.1:5173",
  timeout: 5000
```

## Production Setup (Deno)

Build your SSR bundle to a location accessible by your release, then configure Deno to load it:

```elixir
# config/prod.exs
config :live_react_islands,
  ssr_renderer: LiveReactIslands.SSR.DenoRenderer

config :live_react_islands_ssr_deno,
  main_module_path: "priv/static/assets/ssr.js"
```

## SSR Caching

Cache SSR output for expensive components:

```elixir
# Enable globally
config :live_react_islands,
  ssr_cache: LiveReactIslands.SSR.ETSCache

# Enable per component
use LiveReactIslands.Component,
  component: "ExpensiveChart",
  props: %{data: []},
  ssr_strategy: :overwrite,
  ssr_cache: true  # or [ttl: 60_000] for 60-second cache
```

### Shell Caching

Render a cacheable shell with default values, then hydrate with real data:

```elixir
use LiveReactIslands.Component,
  component: "UserCard",
  props: %{name: "", avatar: ""},
  ssr_strategy: :overwrite,
  ssr_cache: [
    # Render SSR with these placeholder values (cacheable)
    ssr_props: %{name: "Loading...", avatar: "/placeholder.png"},
    # Real props are still sent to client for immediate update
  ]
```

**Why shell caching?** Without it, each unique prop combination requires a separate cache entry. 100 user cards with different names means 100 cached renders. With shell caching, you render one placeholder shell that's reused for all instances. The client updates to real values immediately after mounting, so users see content instantly (no blank space) while avoiding expensive per-instance SSR.

### Custom Cache Implementations

The caching system is extensible via the `LiveReactIslands.SSR.Cache` behaviour. Implement `get_or_render/7` to create your own cache backend (Redis, Memcached, etc.):

```elixir
defmodule MyApp.SSR.RedisCache do
  @behaviour LiveReactIslands.SSR.Cache

  @impl true
  def get_or_render(component_name, id, props, globals, strategy, renderer, opts) do
    # Check Redis, render on miss, cache result
    # Must return {:ok, html_string} or {:error, reason}
  end

  @impl true
  def clear_cache, do: # Clear all entries

  @impl true
  def clear_cache(component_name), do: # Clear entries for component

  @impl true
  def get_stats, do: # Return cache statistics
end
```

The built-in `ETSCache` uses ETS for fast in-memory caching with automatic TTL expiration and thundering herd protection (concurrent requests for the same uncached component only trigger one render).

## Custom SSR Renderers

The SSR system is extensible via the `LiveReactIslands.SSR.Renderer` behaviour. Implement the `render_component/5` callback to create your own renderer for Node.js, Bun, or any JavaScript runtime:

```elixir
defmodule MyApp.SSR.NodeRenderer do
  @behaviour LiveReactIslands.SSR.Renderer

  @impl true
  def render_component(component_name, id, props, globals, strategy) do
    # Call your JS runtime to render the component
    # Must return {:ok, html_string} or {:error, reason}
  end
end
```

The `exposeSSR` function sets up a global `SSR_MODULE` object with the following shape:

```javascript
globalThis.SSR_MODULE = {
  // Main render function - call this from your renderer
  renderSSRIsland(componentName, id, props, globals, strategy) -> string,

  // Strategy-specific renderers (for advanced use)
  hydrateRenderers: { [componentName]: (id, props, globals) -> string },
  overwriteRenderers: { [componentName]: (id, props, globals) -> string },
}
```

The built-in `DenoRenderer` uses [DenoRider](https://github.com/akoutmos/deno_rider) to spawn a Deno process that loads your SSR bundle and calls `SSR_MODULE.renderSSRIsland()` for each render request.
