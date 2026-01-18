defmodule ViteExampleWeb.StaticDemoLive do
  use ViteExampleWeb, :live_view
  import ViteExampleWeb.CoreComponents

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 py-12 px-4">
      <div class="max-w-7xl mx-auto space-y-8">
        <h1 class="text-4xl font-bold text-center text-gray-800 dark:text-gray-100">
          Static Islands Demo
        </h1>

        <div class="flex items-start gap-6 p-6 bg-slate-900 rounded-xl">
        <%!-- 1. Featured --%>
        <.product_card variant="featured">
        <:media>
          <img src="https://picsum.photos/id/425/800/450" class="w-full h-full object-cover" />
        </:media>
        <:badge>Limited Edition</:badge>
        <:title>Ethiopian Yirgacheffe</:title>
        <:price>$24.00</:price>
        <:actions>
          <button class="w-full bg-indigo-600 text-white py-2 rounded-xl font-bold">Add to Cart</button>
        </:actions>
        Notes of jasmine and lemon. Freshly roasted this morning.
        </.product_card>

        <%!-- 2. Simple --%>
        <.product_card>
         <:media>
          <img src="https://picsum.photos/id/119/800/450" class="w-full h-full object-cover" />
        </:media>
        <:title>Digital Gift Card</:title>
        <:price>$50.00</:price>
        Sent instantly to your email. Valid for all varieties.
        </.product_card>

        <%!-- 3. Tutorial --%>
        <.product_card>
        <:media>
          <img src="https://picsum.photos/id/225/800/450" class="w-full h-full object-cover" />
        </:media>
        <:badge>Tutorial</:badge>
        <:title>Brewing Guide</:title>
        <:actions>
          <button class="w-full border border-slate-300 py-2 rounded-xl">Watch Video</button>
        </:actions>
        Learn how to make the perfect pour-over in 5 minutes.
        </.product_card>
        </div>
      </div>
    </div>
    """
  end
end
