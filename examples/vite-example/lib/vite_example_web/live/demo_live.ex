defmodule ViteExampleWeb.DemoLive do
  use ViteExampleWeb, :live_view
  use LiveReactIslands.LiveView, globals: [:user]

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
    <div class="flex items-center justify-center min-h-screen bg-gray-100">
      <div class="bg-white p-8 rounded-lg shadow-lg max-w-2xl">
        <h1 class="text-3xl font-bold text-center mb-6 text-gray-800">
          LiveView Navigation Demo
        </h1>

        <div class="mb-8">
          <div class="grid grid-cols-2 gap-3">
            <div class="group h-full">
              <.link navigate={~p"/push-navigate"} class="flex flex-col justify-center items-center h-full w-full bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white font-medium py-3 px-4 rounded-lg transition-all duration-200 shadow-sm hover:shadow-md text-center">
                <span class="text-base font-semibold">Push Navigate</span>
                <span class="text-xs opacity-90 block mt-0.5">Client-side navigation, keeps WebSocket</span>
              </.link>
            </div>

            <div class="group h-full">
              <.link href={~p"/navigate"} class="flex flex-col justify-center items-center h-full w-full bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white font-medium py-3 px-4 rounded-lg transition-all duration-200 shadow-sm hover:shadow-md text-center">
                <span class="text-base font-semibold">Navigate</span>
                <span class="text-xs opacity-90 block mt-0.5">Full page reload, new WebSocket connection</span>
              </.link>
            </div>
          </div>
        </div>

        <div class="pt-6">
          <p class="text-xs text-gray-800 mb-4">
            Patch navigation - Hidden: state preserved, Unmounted: state lost
          </p>

          <div class="border-b border-gray-200">
            <nav class="flex -mb-px">
              <.link
                patch={~p"/?tab=hidden"}
                class={"px-6 py-3 text-sm font-medium border-b-2 transition-colors " <> if @tab == "hidden", do: "border-purple-600 text-purple-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}
              >
                Hidden
              </.link>
              <.link
                patch={~p"/?tab=unmounted"}
                class={"px-6 py-3 text-sm font-medium border-b-2 transition-colors " <> if @tab == "unmounted", do: "border-purple-600 text-purple-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}
              >
                Unmounted
              </.link>
            </nav>
          </div>

          <div class="bg-gray-50 p-4 rounded mb-4">
            <div style={"display: #{if @tab == "hidden", do: "block", else: "none"}"}>
              <.live_component
                module={ViteExampleWeb.Components.CounterIsland}
                id="hidden_island"
              />
            </div>
            <%= case @tab do %>
              <% "unmounted" -> %>
                <.live_component
                  module={ViteExampleWeb.Components.CounterIsland}
                  id="unmounted_island"
                />
              <% _ -> %> <!-- For home tab, content is already rendered above -->
            <% end %>
          </div>
          <p class="text-xs text-gray-500 italic">
            Watch the browser console: Hidden island never unmounts (no logs), unmounted island gets cleaned up on tab switch.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
