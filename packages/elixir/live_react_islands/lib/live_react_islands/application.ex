defmodule LiveReactIslands.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children =
      case Application.get_env(:live_react_islands, :ssr_cache) do
        # No SSR cache
        nil ->
          []

        # Built-in SSR cache
        LiveReactIslands.SSR.ETSCache ->
          opts = [
            default_ttl: Application.get_env(:live_react_islands, :cache_default_ttl, :timer.minutes(5)),
            cleanup_interval: Application.get_env(:live_react_islands, :cache_cleanup_interval, :timer.minutes(1))
          ]
          [{LiveReactIslands.SSR.ETSCache, opts}]

        # Custom SSR cache: User provides {Mod, Args} or just Mod
        custom ->
          [
            Supervisor.child_spec(custom,
              start: {extract_mod(custom), :start_link, [extract_args(custom)]}
            )
          ]
      end

    startable_children =
      Enum.filter(children, fn
        {mod, _args} ->
          Code.ensure_loaded(mod)
          function_exported?(mod, :start_link, 1)
        _ ->
          false
      end)

    Supervisor.start_link(startable_children, strategy: :one_for_one)
  end

  defp extract_mod({mod, _args}), do: mod
  defp extract_mod(mod), do: mod

  defp extract_args({_mod, args}), do: args
  defp extract_args(_mod), do: []
end
