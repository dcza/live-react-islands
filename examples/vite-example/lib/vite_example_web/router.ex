defmodule ViteExampleWeb.Router do
  use ViteExampleWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {ViteExampleWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/", ViteExampleWeb do
    pipe_through(:browser)

    live("/", DemoLive)
    live("/patch", DemoLive)
    live("/push-navigate", PushNavigateLive)
    live("/navigate", NavigateLive)
    live("/ssr", SSRDemoLive)
  end
end
