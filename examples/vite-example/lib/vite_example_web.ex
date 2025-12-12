defmodule ViteExampleWeb do
  def static_paths, do: ~w(assets fonts images favicon.ico favicon.svg robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: ViteExampleWeb.Layouts]

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {ViteExampleWeb.Layouts, :root}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
      import ViteExampleWeb.CoreComponents

      alias Phoenix.LiveView.JS

      unquote(verified_routes())

      # Helpers to load assets from Vite dev server in dev, built files in prod
      def vite_client_script do
        if Application.get_env(:vite_example, :dev_routes, false) do
          "http://localhost:5173/@vite/client"
        else
          nil
        end
      end

      def vite_js_entry do
        if Application.get_env(:vite_example, :dev_routes, false) do
          "http://localhost:5173/src/main.jsx"
        else
          ~p"/assets/main.js"
        end
      end

      def vite_css_entry do
        if Application.get_env(:vite_example, :dev_routes, false) do
          # Load CSS directly from Vite dev server to avoid FOUC
          # ?direct param tells Vite to return raw CSS instead of JS module
          "http://localhost:5173/src/index.css?direct"
        else
          ~p"/assets/main.css"
        end
      end
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ViteExampleWeb.Endpoint,
        router: ViteExampleWeb.Router,
        statics: ViteExampleWeb.static_paths()
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
