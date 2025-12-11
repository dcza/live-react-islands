defmodule ViteExampleWeb.PushNavigateLive do
  use ViteExampleWeb, :live_view
  use LiveReactIslands.LiveView, globals: [:user]

  def mount(_params, _session, socket) do
    socket = assign(socket, user: %{name: "Jane Smith", email: "jane@example.com"})
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center min-h-screen bg-blue-100">
      <div class="bg-white p-8 rounded-lg shadow-lg">
        <h1 class="text-3xl font-bold text-center mb-6 text-blue-800">
          Push Navigate Target
        </h1>
        <p class="text-gray-600 mb-4">
          This page was reached using <code class="bg-gray-100 px-2 py-1 rounded">push_navigate</code> (client-side navigation)
        </p>

        <div class="my-6">
          <.live_component
            module={ViteExampleWeb.Components.CounterIsland}
            id="push_navigate_island"
          />
        </div>

        <.link navigate={~p"/"} class="inline-block bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
          Back to Home
        </.link>
      </div>
    </div>
    """
  end
end
