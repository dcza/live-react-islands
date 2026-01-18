defmodule ViteExampleWeb.CoreComponents do
  use Phoenix.Component
  alias LiveReactIslands.SSR

  @doc """
  A Product Card component using React for the visual shell.
  """
  attr :variant, :string, values: ["default", "featured", "sale"], default: "default"

  slot :media
  slot :badge
  slot :title, required: true
  slot :price
  slot :actions
  slot :inner_block

  def product_card(assigns) do
    ~H"""
    <div class="flex-1">
      <%= SSR.render_static_template(assigns, "ProductCard") %>
    </div>
    """
  end
end
