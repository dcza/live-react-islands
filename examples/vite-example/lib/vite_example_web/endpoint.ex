defmodule ViteExampleWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :vite_example

  @session_options [
    store: :cookie,
    key: "_vite_example_key",
    signing_salt: "vite_example",
    same_site: "Lax"
  ]

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: false
  )

  socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
  plug(Phoenix.LiveReloader)
  plug(Phoenix.CodeReloader)

  plug(Plug.Static,
    at: "/",
    from: :vite_example,
    gzip: false,
    only: ViteExampleWeb.static_paths()
  )

  plug(Plug.RequestId)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(ViteExampleWeb.Router)
end
