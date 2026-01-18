defmodule LiveReactIslands.SSR do
  @moduledoc """
  SSR rendering utilities.
  """
  use Phoenix.Component

  @reserved_keys [:__changed__, :__given__, :__metas__, :inner_block, :socket, :flash, :myself]

  @doc """
  Renders a React component as a static template with HEEx slot stitching.

  Uses SSR to render a React "shell" with slot markers, then stitches
  HEEx slot content into the result. The shell is aggressively cached
  since marker-based props never change.

  ## Options

  - `:ttl` - Cache TTL in milliseconds, or `:infinity` (default: `:infinity`)

  Options can be passed as function argument (for defaults) or via assigns (takes precedence).

  ## Example

      def product_card(assigns) do
        # Default TTL, can be overridden via assigns
        LiveReactIslands.SSR.render_static_template(assigns, "ProductCard", ttl: :infinity)
      end

      # Override TTL for this instance
      <.product_card variant="featured" ttl={:timer.hours(1)}>
        <:title>My Product</:title>
      </.product_card>

  The React component receives `slots.title`, `slots.price` etc. as marker
  strings which get replaced with the actual HEEx content. Options like
  `:ttl` are not passed to React.
  """
  @opt_keys [:ttl]

  def render_static_template(assigns, react_component, opts \\ []) do
    renderer = Application.get_env(:live_react_islands, :ssr_renderer)
    cache = Application.get_env(:live_react_islands, :ssr_cache)

    unless renderer do
      raise """
      No :ssr_renderer configured for LiveReactIslands.

      Add to your config:

          config :live_react_islands,
            ssr_renderer: LiveReactIslands.SSR.ViteRenderer
      """
    end

    slot_keys =
      assigns
      |> Map.keys()
      |> Enum.filter(fn k ->
        val = Map.get(assigns, k)
        is_list(val) and val != [] and match?(%{__slot__: _}, List.first(val))
      end)
      |> Enum.sort()

    user_props = Map.drop(assigns, @reserved_keys ++ @opt_keys ++ slot_keys)

    assigns_opts = assigns |> Map.take(@opt_keys) |> Keyword.new(fn {k, v} -> {k, v} end)
    opts = Keyword.merge(opts, assigns_opts)

    slots_markers =
      Map.new(slot_keys, fn s ->
        {Atom.to_string(s), "[[slot:#{s}]]"}
      end)

    ssr_props = Map.merge(user_props, %{"slots" => slots_markers})

    cache_opts = [id_in_key: false, ttl: Keyword.get(opts, :ttl, :infinity)]
    id = "static"
    globals = %{__version: 0}
    strategy = :overwrite

    result =
      if cache do
        cache.get_or_render(react_component, id, ssr_props, globals, strategy, renderer, cache_opts)
      else
        renderer.render_component(react_component, id, ssr_props, globals, strategy)
      end

    case result do
      {:ok, html_shell} ->
        stitch_slots(html_shell, slot_keys, assigns)

      {:error, reason} ->
        raise "SSR.render_static_template failed for #{react_component}: #{inspect(reason)}"
    end
  end

  defp stitch_slots(html_shell, slot_keys, parent_assigns) do
    marker_strings = Enum.map(slot_keys, &"[[slot:#{&1}]]")

    marker_regex =
      marker_strings
      |> Enum.map(&Regex.escape/1)
      |> Enum.join("|")
      |> Regex.compile!()

    parts = String.split(html_shell, marker_regex)

    ordered_keys =
      Regex.scan(marker_regex, html_shell)
      |> List.flatten()
      |> Enum.map(fn "[[slot:" <> rest ->
        rest |> String.replace("]]", "") |> String.to_existing_atom()
      end)

    render_stitched(%{
      parts: parts,
      slot_keys: ordered_keys,
      parent_assigns: parent_assigns
    })
  end

  defp render_stitched(assigns) do
    ~H"""
    <%= for {part, index} <- Enum.with_index(@parts) do %><%= Phoenix.HTML.raw(part) %><%= if index < length(@slot_keys) do %><%= render_slot(Map.get(@parent_assigns, Enum.at(@slot_keys, index))) %><% end %><% end %>
    """
  end
end
