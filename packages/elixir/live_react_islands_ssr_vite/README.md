# LiveReactIslands SSR Vite

Vite dev server SSR backend for [LiveReactIslands](https://github.com/dcza/live-react-islands).

This package provides development-mode server-side rendering of React components via HTTP communication with Vite's SSR server.

## Configuration

```elixir
config :live_react_islands,
  ssr_renderer: LiveReactIslands.SSR.ViteRenderer

config :live_react_islands_ssr_vite,
  vite_url: "http://127.0.0.1:5173",
  timeout: 5000
```

## Usage

This renderer communicates with the Vite dev server's SSR endpoint. Make sure your Vite config includes the `@live-react-islands/vite-plugin-ssr` plugin.

For full documentation, see the [main project repository](https://github.com/dcza/live-react-islands).

## License

MIT
