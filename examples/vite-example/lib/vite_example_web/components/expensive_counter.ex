defmodule ViteExampleWeb.Components.ExpensiveCounter do
  @moduledoc """
  ExpensiveCounter for cache demo.

  Each Counter renders a fibonacci(30) during SSR (~10-50ms).
  """

  use LiveReactIslands.Component,
    component: "ExpensiveCounter",
    props: %{title: "", count: 0},
    ssr_strategy: :overwrite,
    ssr_cache: [ssr_props: %{title: "Title"}]

  def handle_event("increment", _params, socket) do
    new_count = socket.assigns.count + 1
    {:noreply, socket |> update_prop(:count, new_count)}
  end
end
