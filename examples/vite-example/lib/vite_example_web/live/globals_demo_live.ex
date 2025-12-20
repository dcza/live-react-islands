defmodule ViteExampleWeb.GlobalsDemoLive do
  use ViteExampleWeb, :live_view
  use LiveReactIslands.LiveView, expose_globals: [:user, :title]

  def mount(_params, _session, socket) do
    socket =
      assign(socket, user: %{name: "John Doe", email: "john@example.com"}, title: "Welcome!")

    {:ok, socket}
  end

  def handle_event("update_user", params, socket) do
    field = params["field"]
    value = params["value"]
    user = socket.assigns.user
    updated_user = Map.put(user, String.to_existing_atom(field), value)
    {:noreply, assign(socket, user: updated_user)}
  end

  def handle_event("update_title", %{"value" => value}, socket) do
    {:noreply, assign(socket, title: value)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 py-12 px-4">
      <div class="max-w-7xl mx-auto">
        <h1 class="text-4xl font-bold text-center mb-4 text-gray-800 dark:text-gray-100">
          Global State Management Demo
        </h1>

        <p class="text-gray-600 dark:text-gray-300 text-center mb-8 max-w-3xl mx-auto">
          This demo shows how globals flow from LiveView to React islands. Update the user data below and watch it propagate to all islands in real-time.
        </p>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          <!-- Control Panel -->
          <div class="bg-white dark:bg-slate-800 rounded-xl shadow-md dark:shadow-slate-900/50 p-6">
            <h2 class="text-2xl font-bold text-gray-800 dark:text-gray-100 mb-4">LiveView Controls</h2>
            <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
              These inputs control the global user state. Changes are immediately sent to all React islands.
            </p>

            <div class="space-y-4">
              <form phx-change="update_title">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Island Title
                </label>
                <input
                  type="text"
                  value={@title}
                  name="value"
                  class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-indigo-500 dark:focus:ring-indigo-400 focus:border-transparent"
                  placeholder="Enter title"
                />
              </form>

              <form phx-change="update_user">
                <input type="hidden" name="field" value="name" />
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  User Name
                </label>
                <input
                  type="text"
                  value={@user.name}
                  name="value"
                  class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-indigo-500 dark:focus:ring-indigo-400 focus:border-transparent"
                  placeholder="Enter name"
                />
              </form>

              <form phx-change="update_user">
                <input type="hidden" name="field" value="email" />
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  User Email
                </label>
                <input
                  type="email"
                  value={@user.email}
                  name="value"
                  class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-indigo-500 dark:focus:ring-indigo-400 focus:border-transparent"
                  placeholder="Enter email"
                />
              </form>

              <div class="pt-4 border-t border-gray-200 dark:border-gray-700">
                <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">Current State:</h3>
                <pre class="bg-gray-100 dark:bg-slate-900 p-3 rounded text-xs text-gray-800 dark:text-gray-200 overflow-auto"><%= Jason.encode!(%{user: @user, title: @title}, pretty: true) %></pre>
              </div>
            </div>
          </div>

          <!-- React Island with Globals -->
          <div class="bg-white dark:bg-slate-800 rounded-xl shadow-md dark:shadow-slate-900/50 p-6">
            <h2 class="text-2xl font-bold text-gray-800 dark:text-gray-100 mb-4">React Island</h2>
            <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
              This React component receives the global user data automatically. It updates whenever the LiveView state changes.
            </p>

            <.live_component
              module={ViteExampleWeb.Components.GlobalsIsland}
              id="globals_demo"
            />
          </div>
        </div>

        <!-- Additional Demo Islands -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div class="bg-white dark:bg-slate-800 rounded-xl shadow-md dark:shadow-slate-900/50 p-6">
            <h3 class="text-lg font-bold text-gray-800 dark:text-gray-100 mb-3">Island #1</h3>
            <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">
              Same component, different instance - demonstrates that all islands receive the same global state.
            </p>
            <.live_component
              module={ViteExampleWeb.Components.GlobalsIsland}
              id="globals_demo_2"
            />
          </div>

          <div class="bg-white dark:bg-slate-800 rounded-xl shadow-md dark:shadow-slate-900/50 p-6">
            <h3 class="text-lg font-bold text-gray-800 dark:text-gray-100 mb-3">Island #2</h3>
            <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">
              Another instance receiving the same globals simultaneously.
            </p>
            <.live_component
              module={ViteExampleWeb.Components.GlobalsIsland}
              id="globals_demo_3"
            />
          </div>

          <div class="bg-white dark:bg-slate-800 rounded-xl shadow-md dark:shadow-slate-900/50 p-6">
            <h3 class="text-lg font-bold text-gray-800 dark:text-gray-100 mb-3">Island #3</h3>
            <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">
              All islands stay in sync with the global state.
            </p>
            <.live_component
              module={ViteExampleWeb.Components.GlobalsIsland}
              id="globals_demo_4"
            />
          </div>
        </div>

        <div class="mt-8 bg-blue-50 dark:bg-blue-900/30 border-l-4 border-blue-500 dark:border-blue-400 p-4 rounded">
          <p class="text-sm text-blue-800 dark:text-blue-200">
            <strong>💡 How it works:</strong> The LiveView exposes <code class="bg-blue-100 dark:bg-blue-800 px-1 rounded">user</code> and <code class="bg-blue-100 dark:bg-blue-800 px-1 rounded">title</code> globals via <code class="bg-blue-100 dark:bg-blue-800 px-1 rounded">expose_globals: [:user, :title]</code>. All React islands automatically receive this data and re-render when it changes. Open the browser console to see update events.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
