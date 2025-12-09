defmodule ViteExampleWeb.HomeLive do
  use ViteExampleWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center min-h-screen bg-gray-100">
      <div class="bg-white p-8 rounded-lg shadow-lg">
        <h1 class="text-3xl font-bold text-center mb-6 text-gray-800">
          LiveReactIslands Vite Example
        </h1>
        <.live_component
          module={ViteExampleWeb.Components.CounterIsland}
          id="counter_1"
        />
         <.live_component
          module={ViteExampleWeb.Components.CounterIsland}
          id="counter_2"
        />
        </div>
    </div>
    """
  end
end
