import Config

config :vite_example,
  generators: [timestamp_type: :utc_datetime]

config :vite_example, ViteExampleWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ViteExampleWeb.ErrorHTML],
    layout: false
  ],
  live_view: [signing_salt: "vite_example_salt"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :live_react_islands,
  ssr_renderer: LiveReactIslands.SSR.DenoRenderer

config :live_react_islands_ssr_deno,
  otp_app: :vite_example,
  main_module_path: "priv/static/assets/ssr.js"

import_config "#{config_env()}.exs"
