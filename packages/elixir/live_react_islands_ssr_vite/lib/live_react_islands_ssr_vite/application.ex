defmodule LiveReactIslands.SSR.ViteRenderer.Application do
  @moduledoc """
  OTP Application for the LiveReactIslands Vite SSR system.

  Starts the ViteRenderer GenServer which connects to the Vite dev server
  for server-side rendering during development.

  Configure in your config files:

      config :live_react_islands_ssr_vite,
        vite_url: "http://127.0.0.1:5173",
        timeout: 5000
  """

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    # Get configuration
    config = Application.get_all_env(:live_react_islands_ssr_vite)

    vite_url = Keyword.get(config, :vite_url, "http://127.0.0.1:5173")
    timeout = Keyword.get(config, :timeout, 5000)

    children = [
      {LiveReactIslands.SSR.ViteRenderer, [vite_url: vite_url, timeout: timeout]}
    ]

    opts = [strategy: :one_for_one, name: LiveReactIslands.SSR.ViteRenderer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
