defmodule ViteExampleWeb.CacheDemoLive do
  use ViteExampleWeb, :live_view
  use LiveReactIslands.LiveView, expose_globals: [:user?]

  alias ViteExampleWeb.Components.ExpensiveCounter

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Update stats every second
      :timer.send_interval(1000, self(), :update_stats)
    end

    socket =
      socket
      |> assign(:user, %{name: "Cache Demo User", email: "demo@example.com"})
      |> assign(:cache_stats, get_cache_stats())
      |> assign(:island_count, 100)
      |> assign(:remount_key, 0)
      |> assign(:last_render_time, nil)

    {:ok, socket}
  end

  def handle_info(:update_stats, socket) do
    {:noreply, assign(socket, :cache_stats, get_cache_stats())}
  end

  def handle_event("clear_cache", _params, socket) do
    case Application.get_env(:live_react_islands, :ssr_cache) do
      nil -> :ok
      cache_module -> cache_module.clear_cache()
    end

    {:noreply, assign(socket, :cache_stats, get_cache_stats())}
  end

  def handle_event("remount_islands", _params, socket) do
    start_time = System.monotonic_time(:millisecond)

    socket =
      socket
      |> update(:remount_key, &(&1 + 1))
      |> assign(:last_render_time, nil)

    # Calculate render time (this will be inaccurate but gives a rough idea)
    render_time = System.monotonic_time(:millisecond) - start_time

    {:noreply, assign(socket, :last_render_time, render_time)}
  end

  def handle_event("change_count", %{"count" => count}, socket) do
    count = String.to_integer(count)
    {:noreply, assign(socket, :island_count, count)}
  end

  defp get_cache_stats do
    case Application.get_env(:live_react_islands, :ssr_cache) do
      nil ->
        %{size: 0, memory: 0, type: :none}

      cache_module ->
        try do
          cache_module.get_stats()
        rescue
          _ -> %{size: 0, memory: 0, type: :error}
        catch
          :exit, _ -> %{size: 0, memory: 0, type: :not_started}
        end
    end
  end

  defp format_bytes(bytes) when is_integer(bytes) do
    cond do
      bytes < 1024 -> "#{bytes} B"
      bytes < 1024 * 1024 -> "#{Float.round(bytes / 1024, 2)} KB"
      true -> "#{Float.round(bytes / (1024 * 1024), 2)} MB"
    end
  end

  defp format_bytes(_), do: "N/A"
end
