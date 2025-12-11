defmodule ViteExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :vite_example,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {ViteExample.Application, []},
      extra_applications: [:logger, :live_react_islands_ssr_deno]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.18"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 1.0.1"},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.5"},
      {:live_react_islands, path: "../../packages/elixir/live_react_islands"},
      {:live_react_islands_ssr_deno, path: "../../packages/elixir/live_react_islands_ssr_deno"}
    ]
  end
end
