import Config

# Configure SSR renderer for test (Deno-based)
config :live_react_islands,
  ssr_renderer: LiveReactIslands.SSR.DenoRenderer

config :live_react_islands_ssr_deno,
  otp_app: :vite_example,
  main_module_path: "priv/static/assets/ssr.js"
