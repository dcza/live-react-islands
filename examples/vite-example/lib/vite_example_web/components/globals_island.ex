defmodule ViteExampleWeb.Components.GlobalsIsland do
  use LiveReactIslands.Component,
    component: "Counter",
    props: %{count: 0},
    globals: [:user, :title]

  def update(assigns, socket) do
    # Call super to get default prop initialization and ownership tracking
    {:ok, socket} = super(assigns, socket)

    # Then add any custom logic
    title = assigns[:title] || "Globals Demo"
    {:ok, assign(socket, :title, title)}
  end

  def handle_event("increment", _params, socket) do
    new_count = socket.assigns.count + 1
    {:noreply, socket |> update_prop(:count, new_count)}
  end
end
