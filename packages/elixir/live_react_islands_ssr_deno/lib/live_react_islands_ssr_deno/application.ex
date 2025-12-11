defmodule LiveReactIslands.SSR.DenoRenderer.Application do
  @moduledoc """
  OTP Application for the LiveReactIslands SSR system.

  This allows LiveReactIslands to be configured and managed as a separate
  application within the project.

  Configure in your config files:

      config :live_react_islands, LiveReactIslands,
        main_module_path: "priv/static/assets/ssr.js"
  """

  use Application

  @impl true
  def start(_type, _args) do
    # Get configuration
    config = Application.get_all_env(:live_react_islands_ssr_deno)

    otp_app =
      Keyword.get(config, :otp_app) ||
        raise """
        LiveReactIslandsSSRDeno otp_app not configured!

        Add to your config/config.exs:

            config :live_react_islands_ssr_deno,
              otp_app: :my_phoenix_app
        """

    relative_path =
      Keyword.get(config, :main_module_path) ||
        raise """
        LiveReactIslandsSSRDeno main_module_path not configured!

        Add to your config/config.exs:

            config :live_react_islands_ssr_deno,
              main_module_path: "priv/static/assets/ssr.js"
        """

    # Resolve the path relative to the application's priv directory
    main_module_path =
      if String.starts_with?(relative_path, "priv/") do
        # Convert priv/... to absolute path using Application.app_dir
        priv_relative = String.replace_prefix(relative_path, "priv/", "")
        Path.join(Application.app_dir(otp_app, "priv"), priv_relative)
      else
        # Already an absolute path or relative to cwd
        relative_path
      end

    children = [
      {LiveReactIslands.SSR.DenoRenderer, [main_module_path: main_module_path]}
    ]

    opts = [strategy: :one_for_one, name: LiveReactIslands.SSR.DenoRenderer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
