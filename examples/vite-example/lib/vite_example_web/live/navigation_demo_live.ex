defmodule ViteExampleWeb.NavigationDemoLive do
  use ViteExampleWeb, :live_view
  use LiveReactIslands.LiveView, expose_globals: [:user]

  def mount(_params, _session, socket) do
    socket = assign(socket, user: %{name: "John Doe", email: "john.doe@gmail.com"})
    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    tab = params["tab"] || "hidden"
    {:noreply, assign(socket, tab: tab)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 py-12 px-4">
      <div class="max-w-2xl mx-auto">
        <h1 class="text-4xl font-bold text-center mb-4 text-gray-800 dark:text-gray-100">
          LiveView Navigation Demo
        </h1>

        <p class="text-gray-600 dark:text-gray-300 text-center mb-8 max-w-xl mx-auto">
          Explore different navigation strategies and how they affect React island lifecycle. Watch the browser console to observe mount/unmount behavior.
        </p>

        <div class="mb-8">
          <div class="grid grid-cols-2 gap-3">
            <div class="group h-full">
              <.link navigate={~p"/push-navigate"} class="flex flex-col justify-center items-center h-full w-full bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 dark:from-blue-600 dark:to-blue-700 dark:hover:from-blue-700 dark:hover:to-blue-800 text-white font-medium py-3 px-4 rounded-lg transition-all duration-200 shadow-sm hover:shadow-md text-center">
                <span class="text-base font-semibold">Push Navigate</span>
                <span class="text-xs opacity-90 block mt-0.5">Client-side navigation, keeps WebSocket</span>
              </.link>
            </div>

            <div class="group h-full">
              <.link href={~p"/navigate"} class="flex flex-col justify-center items-center h-full w-full bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 dark:from-green-600 dark:to-green-700 dark:hover:from-green-700 dark:hover:to-green-800 text-white font-medium py-3 px-4 rounded-lg transition-all duration-200 shadow-sm hover:shadow-md text-center">
                <span class="text-base font-semibold">Navigate</span>
                <span class="text-xs opacity-90 block mt-0.5">Full page reload, new WebSocket connection</span>
              </.link>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-slate-800 rounded-xl shadow-md dark:shadow-slate-900/50 p-6">
          <p class="text-sm text-gray-700 dark:text-gray-300 mb-4">
            <strong>Patch navigation:</strong> Hidden preserves component state, Unmounted loses state
          </p>

          <div class="border-b border-gray-200 dark:border-gray-700">
            <nav class="flex -mb-px">
              <.link
                patch={~p"/navigation?tab=hidden"}
                class={"px-6 py-3 text-sm font-medium border-b-2 transition-colors " <> if @tab == "hidden", do: "border-purple-600 dark:border-purple-400 text-purple-600 dark:text-purple-400", else: "border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:border-gray-300 dark:hover:border-gray-600"}
              >
                Hidden
              </.link>
              <.link
                patch={~p"/navigation?tab=unmounted"}
                class={"px-6 py-3 text-sm font-medium border-b-2 transition-colors " <> if @tab == "unmounted", do: "border-purple-600 dark:border-purple-400 text-purple-600 dark:text-purple-400", else: "border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:border-gray-300 dark:hover:border-gray-600"}
              >
                Unmounted
              </.link>
            </nav>
          </div>

          <div class="bg-gray-50 dark:bg-slate-900 p-4 rounded-lg my-4">
            <div style={"display: #{if @tab == "hidden", do: "block", else: "none"}"}>
              <.live_component
                module={ViteExampleWeb.Components.CounterIslandSSROverwrite}
                title="Counter Island (Hidden)"
                id="hidden_island"
              />
            </div>
            <%= case @tab do %>
              <% "unmounted" -> %>
                <.live_component
                  module={ViteExampleWeb.Components.CounterIslandSSROverwrite}
                  title="Counter Island (Unmounted)"
                  id="unmounted_island"
                />
              <% _ -> %> <!-- For home tab, content is already rendered above -->
            <% end %>
          </div>
          <p class="text-xs text-gray-600 dark:text-gray-400 italic">
            Watch the browser console: Hidden island never unmounts (no logs), unmounted island gets cleaned up on tab switch.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
