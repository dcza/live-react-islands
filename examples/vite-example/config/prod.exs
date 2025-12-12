import Config

# Configure Deno SSR renderer for production
config :live_react_islands,
  ssr_renderer: LiveReactIslands.SSR.DenoRenderer

config :live_react_islands_ssr_deno,
  otp_app: :vite_example,
  main_module_path: "priv/static/assets/ssr.js"
