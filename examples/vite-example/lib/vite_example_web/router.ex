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

    scope "/.well-known/appspecific" do
      get("/com.chrome.devtools.json", PageController, :ignore)
    end

    get("/", PageController, :index)

    live_session :default, layout: {ViteExampleWeb.Layouts, :app} do
      live("/navigation", NavigationDemoLive)
      live("/push-navigate", PushNavigateLive)
      live("/navigate", NavigateLive)
      live("/ssr", SSRDemoLive)
      live("/globals", GlobalsDemoLive)
      live("/cache", CacheDemoLive)
      live("/form", FormDemoLive)
      live("/static", StaticDemoLive)
    end
  end
end
