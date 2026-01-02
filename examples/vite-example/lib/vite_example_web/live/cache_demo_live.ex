defmodule ViteExampleWeb.CacheDemoLive do
  use ViteExampleWeb, :live_view
  use LiveReactIslands.LiveView

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Update stats every second
      :timer.send_interval(1000, self(), :update_stats)

      handler_id = "lri-timer-#{inspect(self())}"

      :telemetry.attach(
        handler_id,
        [:phoenix, :live_view, :render, :stop],
        &ViteExampleWeb.CacheDemoLive.handle_telemetry/4,
        %{pid: self()}
      )
    end

    socket =
      socket
      |> assign(:cache_stats, get_cache_stats())
      |> assign(:island_count, 100)
      |> assign(:remount_key, 0)
      |> assign(:render_history, [])

    {:ok, socket}
  end

  def handle_telemetry(_name, measurements, metadata, %{pid: target_pid}) do
    case metadata.socket do
      %{root_pid: ^target_pid} ->
        ms = System.convert_time_unit(measurements.duration, :native, :microsecond) / 1000
        send(target_pid, {:update_render_time, Float.round(ms, 2)})

      _ ->
        :ok
    end
  end

  def handle_info(:update_stats, socket) do
    {:noreply, assign(socket, :cache_stats, get_cache_stats())}
  end

  def handle_info({:update_render_time, ms}, socket) do
    # We only want to log 'Interesting' renders.
    # If the render took less than, say, 1ms, it was almost certainly
    # just the timer updating itself, not an actual UI change.
    if ms > 1.0 do
      entry = %{time: ms, type: classify(ms), timestamp: Time.utc_now()}
      history = [entry | socket.assigns.render_history] |> Enum.take(10)
      {:noreply, assign(socket, render_history: history)}
    else
      # DO NOT update assigns. This breaks the loop.
      {:noreply, socket}
    end
  end

  defp classify(ms) when ms > 10, do: :ssr_cold
  defp classify(_), do: :ssr_warm

  def handle_event("clear_cache", _params, socket) do
    case Application.get_env(:live_react_islands, :ssr_cache) do
      nil -> :ok
      cache_module -> cache_module.clear_cache()
    end

    {:noreply, assign(socket, :cache_stats, get_cache_stats())}
  end

  def handle_event("remount_islands", _params, socket) do
    {:noreply,
     socket
     |> update(:remount_key, &(&1 + 1))}
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
