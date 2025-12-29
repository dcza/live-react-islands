defmodule ViteExampleWeb.Components.ExpensiveCounter do
  @moduledoc """
  ExpensiveCounter for cache demo.

  Each Counter renders a fibonacci(30) during SSR (~10-50ms).
  Cache behavior (id_in_key) is controlled via runtime opts from the LiveView.
  """

  use LiveReactIslands.Component,
    component: "ExpensiveCounter",
    props: %{title: "Cached", count: 0},
    ssr_strategy: :overwrite,
    ssr_cache: true

  def handle_event("increment", _params, socket) do
    new_count = socket.assigns.count + 1
    {:noreply, socket |> update_prop(:count, new_count)}
  end
end
