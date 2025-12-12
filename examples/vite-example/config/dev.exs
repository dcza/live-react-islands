import Config

config :vite_example, ViteExampleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  # This is an example secret - do not commit real secrets to git
  secret_key_base: "Wd9PeeXR7ntZ3ArAcfHWvKQcT4rW7aO/BQHVqXdod85epq78+oQgbDsHfJFCzTPP"

config :vite_example, dev_routes: true

# Configure SSR Vite backend for development
config :live_react_islands,
  ssr_renderer: LiveReactIslands.SSR.ViteRenderer

config :live_react_islands_ssr_vite,
  vite_url: "http://127.0.0.1:5173",
  timeout: 5000

config :logger, :console, format: "[$level] $message\n", level: :debug

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
config :phoenix_live_view, :debug_heex_annotations, true
