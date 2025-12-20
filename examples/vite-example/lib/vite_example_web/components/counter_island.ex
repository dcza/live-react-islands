defmodule ViteExampleWeb.Components.CounterIsland do
  use LiveReactIslands.Component,
    component: "Counter",
    props: %{title: "Counter Island (No SSR)", count: 0},
    globals: [:user?]

  def handle_event("increment", _params, socket) do
    new_count = socket.assigns.count + 1
    {:noreply, socket |> update_prop(:count, new_count)}
  end
end
