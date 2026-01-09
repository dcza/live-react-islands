defmodule LiveReactIslands do
  @moduledoc """
  Minimal setup required:

    `use LiveReactIslands.LiveView` in every Phoenix LiveView that intends to render an island component.

    `use LiveReactIslands.Component` in all Elixir side island components that act as a server side controller for their specific React island.
    This internally calls `use Phoenix.LiveComponent` and is used like a regular LiveComponenet in your LiveViews.
  """
end
