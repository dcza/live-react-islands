defmodule ViteExampleWeb.NavigateLive do
  use ViteExampleWeb, :live_view
  use LiveReactIslands.LiveView, globals: [:user]

  def mount(_params, _session, socket) do
    socket = assign(socket, user: %{name: "Bob Johnson", email: "bob@example.com"})
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center min-h-screen bg-green-100">
      <div class="bg-white p-8 rounded-lg shadow-lg">
        <h1 class="text-3xl font-bold text-center mb-6 text-green-800">
          Navigate Target
        </h1>
        <p class="text-gray-600 mb-4">
          This page was reached using <code class="bg-gray-100 px-2 py-1 rounded">navigate</code> (full page load)
        </p>

        <div class="my-6">
          <.live_component
            module={ViteExampleWeb.Components.CounterIslandSSROverwrite}
            id="navigate_island"
          />
        </div>

        <.link navigate={~p"/navigation"} class="inline-block bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
          Back to Home
        </.link>
      </div>
    </div>
    """
  end
end
