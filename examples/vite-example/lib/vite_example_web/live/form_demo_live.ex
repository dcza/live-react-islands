defmodule ViteExampleWeb.FormDemoLive do
  use ViteExampleWeb, :live_view
  use LiveReactIslands.LiveView

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 py-12 px-4">
      <div class="max-w-7xl mx-auto">
        <h1 class="text-4xl font-bold text-center mb-4 text-gray-800 dark:text-gray-100">
          React Forms with Ecto Changesets
        </h1>

        <p class="text-gray-600 dark:text-gray-300 text-center mb-8 max-w-3xl mx-auto">
          This demo shows how to use the <code class="bg-gray-200 dark:bg-gray-700 px-1 rounded">useForm</code>
          hook with Ecto changesets for server-side validation. Form state and errors flow seamlessly between React and Elixir.
        </p>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          <!-- React Form Island -->
          <div class="bg-white dark:bg-slate-800 rounded-xl shadow-md dark:shadow-slate-900/50 p-6">
            <h2 class="text-2xl font-bold text-gray-800 dark:text-gray-100 mb-4">React Form Island</h2>
            <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
              This form is rendered by React but validated server-side using Ecto changesets.
              Try submitting with invalid data to see real-time validation.
            </p>

            <.live_component module={ViteExampleWeb.Components.ContactFormIsland} id="contact_form" />
          </div>

          <!-- Explanation Panel -->
          <div class="bg-white dark:bg-slate-800 rounded-xl shadow-md dark:shadow-slate-900/50 p-6">
            <h2 class="text-2xl font-bold text-gray-800 dark:text-gray-100 mb-4">How It Works</h2>

            <div class="space-y-4 text-sm text-gray-600 dark:text-gray-300">
              <div class="bg-blue-50 dark:bg-blue-900/30 p-4 rounded-lg">
                <h3 class="font-semibold text-blue-800 dark:text-blue-200 mb-2">1. Schema Definition</h3>
                <p>Define your Ecto schema with validations as usual. No database required - we use embedded schemas.</p>
              </div>

              <div class="bg-purple-50 dark:bg-purple-900/30 p-4 rounded-lg">
                <h3 class="font-semibold text-purple-800 dark:text-purple-200 mb-2">2. Island Component</h3>
                <p>
                  Use <code class="bg-purple-100 dark:bg-purple-800 px-1 rounded">init_form/3</code> in
                  <code class="bg-purple-100 dark:bg-purple-800 px-1 rounded">init/2</code> and
                  <code class="bg-purple-100 dark:bg-purple-800 px-1 rounded">update_form/3</code> in event handlers.
                </p>
              </div>

              <div class="bg-emerald-50 dark:bg-emerald-900/30 p-4 rounded-lg">
                <h3 class="font-semibold text-emerald-800 dark:text-emerald-200 mb-2">3. React Hook</h3>
                <p>
                  Use the <code class="bg-emerald-100 dark:bg-emerald-800 px-1 rounded">useForm</code> hook
                  to connect form inputs to server state with
                  <code class="bg-emerald-100 dark:bg-emerald-800 px-1 rounded">getFieldProps</code> and
                  <code class="bg-emerald-100 dark:bg-emerald-800 px-1 rounded">getError</code>.
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-8 bg-blue-50 dark:bg-blue-900/30 border-l-4 border-blue-500 dark:border-blue-400 p-4 rounded">
          <p class="text-sm text-blue-800 dark:text-blue-200">
            <strong>Key Features:</strong>
            <ul class="mt-2 space-y-1 list-disc list-inside">
              <li>Field types extracted from Ecto schema (boolean fields render as checkboxes)</li>
              <li>Required fields marked automatically based on changeset validations</li>
              <li>Real-time validation on every keystroke</li>
              <li>Optimistic UI updates with server state sync</li>
            </ul>
          </p>
        </div>
      </div>
    </div>
    """
  end
end
