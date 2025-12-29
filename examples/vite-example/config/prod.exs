import Config

# Configure Deno SSR renderer for production
config :live_react_islands,
  ssr_renderer: LiveReactIslands.SSR.DenoRenderer,
  ssr_cache: LiveReactIslands.SSR.ETSCache,
  cache_default_ttl: :timer.minutes(5),
  cache_cleanup_interval: :timer.minutes(1)

config :live_react_islands_ssr_deno,
  otp_app: :vite_example,
  main_module_path: "priv/static/assets/ssr.js"
