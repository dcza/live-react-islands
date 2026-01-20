# LiveReactIslands SSR Deno

Deno-based SSR renderer for [LiveReactIslands](https://github.com/dcza/live-react-islands).

This package provides server-side rendering of React components using the Deno runtime via [deno_rider](https://hex.pm/packages/deno_rider), suitable for production deployments without requiring a Node.js server.

## Configuration

```elixir
config :live_react_islands,
  ssr_renderer: LiveReactIslands.SSR.DenoRenderer

config :live_react_islands_ssr_deno,
  otp_app: :my_app,
  main_module_path: "priv/static/assets/ssr.js",
  timeout: 5000
```

For full documentation, see the [main project repository](https://github.com/dcza/live-react-islands).

## License

MIT
