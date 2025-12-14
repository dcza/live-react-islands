defmodule ViteExampleWeb.Components.CounterIslandSSRHydrate do
  use LiveReactIslands.Component,
    # This corresponds to the property name in the 'islands' object passed to createHooks
    component: "Counter",
    # Only props defined here will get pushed down to React
    props: %{title: "Counter Island (Hydrate SSR)", count: 0},
    ssr_strategy: :hydrate_root

  def handle_event("increment", _params, socket) do
    new_count = socket.assigns.count + 1
    {:noreply, socket |> update_prop(:count, new_count)}
  end
end
