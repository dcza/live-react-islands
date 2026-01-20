defmodule LiveReactIslands.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/dcza/live-react-islands"

  def project do
    [
      app: :live_react_islands,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      docs: docs(),
      name: "LiveReactIslands",
      source_url: @source_url,
      aliases: aliases()
    ]
  end

  defp aliases do
    [
      "hex.publish": ["cmd cp ../../../README.md", "hex.publish"],
      "hex.build": ["cmd cp ../../../README.md", "hex.build"]
    ]
  end

  def application do
    [
      mod: {LiveReactIslands.Application, []},
      extra_applications: [:logger, :crypto]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix_live_view, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:ecto, "~> 3.10", optional: true},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    React Islands for Phoenix LiveView. Embed React components in LiveView with
    bidirectional communication, server-side rendering, and global state management.
    """
  end

  defp package do
    [
      name: "live_react_islands",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      maintainers: ["David Czaplinski"]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "../../../README.md": [title: "Overview"],
        "../../../docs/SSR.md": [title: "SSR"]
      ],
      assets: %{"../../../docs" => "docs"},
      groups_for_modules: [
        Core: [
          LiveReactIslands,
          LiveReactIslands.Application
        ],
        Components: [
          LiveReactIslands.LiveView,
          LiveReactIslands.Component,
          LiveReactIslands.SSR
        ]
      ]
    ]
  end
end
