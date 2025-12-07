import Config

config :vite_example, ViteExampleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  # This is an example secret - do not commit real secrets to git
  secret_key_base: "Wd9PeeXR7ntZ3ArAcfHWvKQcT4rW7aO/BQHVqXdod85epq78+oQgbDsHfJFCzTPP",
  watchers: [
    yarn: ["workspace", "vite-example", "run", "dev", cd: Path.expand("../../", __DIR__)]
  ]

config :vite_example, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
config :phoenix_live_view, :debug_heex_annotations, true
