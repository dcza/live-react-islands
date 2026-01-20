defmodule LiveReactIslands.SSR.Deno.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/dcza/live-react-islands"

  def project do
    [
      app: :live_react_islands_ssr_deno,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "LiveReactIslands SSR Deno",
      source_url: @source_url
    ]
  end

  def application do
    [
      mod: {LiveReactIslands.SSR.DenoRenderer.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:live_react_islands, "~> 0.1"},
      {:deno_rider, "~> 0.2"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Deno-based SSR renderer for LiveReactIslands. Provides server-side rendering
    of React components using Deno runtime.
    """
  end

  defp package do
    [
      name: "live_react_islands_ssr_deno",
      files: ~w(lib mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      },
      maintainers: ["David Czaplinski"]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end
end
