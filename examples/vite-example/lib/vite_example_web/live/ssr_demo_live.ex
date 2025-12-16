defmodule ViteExampleWeb.SSRDemoLive do
  use ViteExampleWeb, :live_view
  use LiveReactIslands.LiveView, expose_globals: [:user]

  def mount(_params, _session, socket) do
    socket = assign(socket, user: %{name: "Demo User", email: "demo@example.com"})
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-linear-to-br from-slate-50 to-slate-100 py-12 px-4">
      <div class="max-w-7xl mx-auto">
        <h1 class="text-4xl font-bold text-center mb-4 text-gray-800">
          Server-Side Rendering Strategies
        </h1>

        <p class="text-gray-600 text-center mb-6 max-w-3xl mx-auto">
          This demo shows three different SSR strategies for React islands. Watch the browser console and network tab to see the differences in initial rendering and hydration behavior.
        </p>

        <div class="flex justify-center mb-8">
          <button
            onclick="window.location.href = '/ssr'"
            class="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-6 rounded-lg shadow-md hover:shadow-lg transition-all duration-200 cursor-pointer"
          >
            🔄 Reload Page
          </button>
        </div>

        <div class="grid grid-cols-3 gap-6">
          <!-- No SSR (Client-Only) -->
          <div class="bg-white rounded-xl shadow-md p-6">
            <div class="mb-4">
              <h2 class="text-lg font-bold text-gray-800 mb-2">Client-Side Only (No SSR)</h2>
              <p class="text-xs text-gray-600">
                Component renders only in the browser after JavaScript loads. Initial HTML contains just a placeholder, causing a visible content flash on page load.
              </p>
            </div>
            <.live_component
              module={ViteExampleWeb.Components.CounterIsland}
              id="counter_no_ssr"
            />
          </div>

          <!-- SSR with Overwrite -->
          <div class="bg-white rounded-xl shadow-md p-6">
            <div class="mb-4">
              <h2 class="text-lg font-bold text-gray-800 mb-2">SSR with Overwrite</h2>
              <p class="text-xs text-gray-600">
                Server renders initial HTML, but React completely replaces it on load rather than hydrating. Useful when server and client states may differ or for debugging hydration issues.
              </p>
            </div>
            <.live_component
              module={ViteExampleWeb.Components.CounterIslandSSROverwrite}
              id="counter_ssr_overwrite"
            />
          </div>

          <!-- SSR with Hydrate -->
          <div class="bg-white rounded-xl shadow-md p-6">
            <div class="mb-4">
              <h2 class="text-lg font-bold text-gray-800 mb-2">SSR with Hydration</h2>
              <p class="text-xs text-gray-600">
                Server renders HTML that's sent immediately, then React "hydrates" by attaching event listeners. Fastest perceived load time with full interactivity after hydration.
              </p>
            </div>
            <.live_component
              module={ViteExampleWeb.Components.CounterIslandSSRHydrate}
              id="counter_ssr_hydrate"
            />
          </div>
        </div>

        <div class="mt-8 bg-blue-50 border-l-4 border-blue-500 p-4 rounded">
          <p class="text-sm text-blue-800">
            <strong>💡 Tip:</strong> Open the browser console and network tab, then reload the page. You'll see how each strategy differs in timing and behavior.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
