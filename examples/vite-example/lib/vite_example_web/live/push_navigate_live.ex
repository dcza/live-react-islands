defmodule ViteExampleWeb.PushNavigateLive do
  use ViteExampleWeb, :live_view
  use LiveReactIslands.LiveView, expose_globals: [:user]

  def mount(_params, _session, socket) do
    socket = assign(socket, user: %{name: "Jane Smith", email: "jane@example.com"})
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 py-12 px-4">
      <div class="max-w-2xl mx-auto">
        <div class="bg-white dark:bg-slate-800 rounded-xl shadow-md dark:shadow-slate-900/50 p-8">
          <h1 class="text-4xl font-bold text-center mb-4 text-gray-800 dark:text-gray-100">
            Push Navigate Target
          </h1>
          <p class="text-gray-600 dark:text-gray-300 text-center mb-6">
            This page was reached using <code class="bg-gray-100 dark:bg-slate-700 px-2 py-1 rounded text-gray-800 dark:text-gray-200">push_navigate</code> (client-side navigation)
          </p>

          <div class="my-6 bg-gray-50 dark:bg-slate-900 p-4 rounded-lg">
            <.live_component
              module={ViteExampleWeb.Components.CounterIslandSSROverwrite}
              id="push_navigate_island"
            />
          </div>

          <div class="flex justify-center">
            <.link navigate={~p"/navigation"} class="inline-block bg-indigo-600 hover:bg-indigo-700 dark:bg-indigo-500 dark:hover:bg-indigo-600 text-white font-semibold py-2 px-6 rounded-lg shadow-md hover:shadow-lg transition-all duration-200">
              Back to Navigation Demo
            </.link>
          </div>

          <div class="mt-6 bg-blue-50 dark:bg-blue-900/30 border-l-4 border-blue-500 dark:border-blue-400 p-4 rounded">
            <p class="text-sm text-blue-800 dark:text-blue-200">
              <strong>💡 Note:</strong> This navigation maintained the WebSocket connection. Check the browser console - the island was preserved across navigation.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
