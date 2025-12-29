defmodule LiveReactIslands.SSR.ETSCacheTest do
  use ExUnit.Case, async: false

  alias LiveReactIslands.SSR.ETSCache

  # Mock renderer module for testing
  defmodule MockRenderer do
    def render_component("Counter", _id, _props, _globals, _strategy) do
      {:ok, "<div>Counter: 0</div>"}
    end

    def render_component("ExpensiveChart", _id, _props, _globals, _strategy) do
      {:ok, "<div>Chart</div>"}
    end

    def render_component("SlowComponent", _id, _props, _globals, _strategy) do
      # Simulate slow render
      Process.sleep(100)
      {:ok, "<div>Slow</div>"}
    end

    def render_component("ErrorComponent", _id, _props, _globals, _strategy) do
      {:error, :render_error}
    end
  end

  setup do
    # Stop any existing cache
    case Process.whereis(ETSCache) do
      pid when is_pid(pid) ->
        try do
          GenServer.stop(ETSCache, :normal)
        catch
          :exit, _ -> :ok
        end

        Process.sleep(10)

      nil ->
        :ok
    end

    # Start cache with test config
    {:ok, _pid} =
      ETSCache.start_link(
        default_ttl: 1000,
        cleanup_interval: 500
      )

    on_exit(fn ->
      case Process.whereis(ETSCache) do
        pid when is_pid(pid) ->
          try do
            GenServer.stop(ETSCache, :normal)
          catch
            :exit, _ -> :ok
          end

        nil ->
          :ok
      end
    end)

    :ok
  end

  describe "cache hits and misses" do
    test "cache miss triggers render" do
      assert {:ok, html} =
               ETSCache.get_or_render(
                 "Counter",
                 "counter-1",
                 %{count: 0},
                 %{},
                 :overwrite,
                 MockRenderer
               )

      assert html == "<div>Counter: 0</div>"
    end

    test "cache hit returns cached result" do
      # First call - cache miss
      {:ok, _html1} =
        ETSCache.get_or_render(
          "Counter",
          "counter-1",
          %{count: 0},
          %{},
          :overwrite,
          MockRenderer
        )

      # Second call - cache hit (should be instant)
      start_time = System.monotonic_time(:millisecond)

      {:ok, html2} =
        ETSCache.get_or_render(
          "Counter",
          "counter-1",
          %{count: 0},
          %{},
          :overwrite,
          MockRenderer
        )

      elapsed = System.monotonic_time(:millisecond) - start_time

      assert html2 == "<div>Counter: 0</div>"
      # Cache hit should be very fast (< 10ms)
      assert elapsed < 10
    end

    test "different props generate different cache keys" do
      {:ok, html1} =
        ETSCache.get_or_render(
          "Counter",
          "counter-1",
          %{count: 0},
          %{},
          :overwrite,
          MockRenderer
        )

      {:ok, html2} =
        ETSCache.get_or_render(
          "Counter",
          "counter-1",
          %{count: 1},
          %{},
          :overwrite,
          MockRenderer
        )

      # Both should render successfully
      assert html1 == "<div>Counter: 0</div>"
      assert html2 == "<div>Counter: 0</div>"
    end

    test "same props but different IDs use same cache (default id_in_key: false)" do
      {:ok, _html1} =
        ETSCache.get_or_render(
          "Counter",
          "counter-1",
          %{count: 0},
          %{},
          :overwrite,
          MockRenderer
        )

      # Different ID, same props - should hit cache (default id_in_key: false excludes ID)
      start_time = System.monotonic_time(:millisecond)

      {:ok, html2} =
        ETSCache.get_or_render(
          "Counter",
          "counter-2",
          %{count: 0},
          %{},
          :overwrite,
          MockRenderer
        )

      elapsed = System.monotonic_time(:millisecond) - start_time

      assert html2 == "<div>Counter: 0</div>"
      # Should be cache hit (fast)
      assert elapsed < 10
    end

    test "id_in_key: true creates separate cache entries per ID" do
      {:ok, _html1} =
        ETSCache.get_or_render(
          "Counter",
          "counter-1",
          %{count: 0},
          %{},
          :overwrite,
          MockRenderer,
          id_in_key: true
        )

      # Different ID with id_in_key: true - should create separate cache entry
      {:ok, html2} =
        ETSCache.get_or_render(
          "Counter",
          "counter-2",
          %{count: 0},
          %{},
          :overwrite,
          MockRenderer,
          id_in_key: true
        )

      assert html2 == "<div>Counter: 0</div>"

      # Verify we have 2 separate cache entries (same component, same props, different IDs)
      stats = ETSCache.get_stats()
      assert stats.size == 2
    end
  end

  describe "TTL expiration" do
    test "cache entry expires after TTL" do
      # Render with 100ms TTL
      {:ok, _html} =
        ETSCache.get_or_render(
          "Counter",
          "counter-1",
          %{count: 0},
          %{},
          :overwrite,
          MockRenderer,
          ttl: 100
        )

      # Wait for expiration
      Process.sleep(150)

      # Should trigger fresh render (cache expired)
      # Note: May return :expired_during_wait if entry expires between checks
      result =
        ETSCache.get_or_render(
          "Counter",
          "counter-1",
          %{count: 0},
          %{},
          :overwrite,
          MockRenderer,
          ttl: 100
        )

      case result do
        {:ok, html} -> assert html == "<div>Counter: 0</div>"
        {:error, :expired_during_wait} -> :ok
      end
    end

    test "component-specific TTL via opts overrides default" do
      # Pass TTL via opts (2000ms)
      {:ok, _html} =
        ETSCache.get_or_render(
          "ExpensiveChart",
          "chart-1",
          %{data: []},
          %{},
          :overwrite,
          MockRenderer,
          ttl: 2000
        )

      # Should still be cached after 1500ms (default TTL is 1000ms, but we passed 2000ms)
      Process.sleep(1500)

      start_time = System.monotonic_time(:millisecond)

      {:ok, html2} =
        ETSCache.get_or_render(
          "ExpensiveChart",
          "chart-1",
          %{data: []},
          %{},
          :overwrite,
          MockRenderer,
          ttl: 2000
        )

      elapsed = System.monotonic_time(:millisecond) - start_time

      assert html2 == "<div>Chart</div>"
      # Should be cache hit (fast)
      assert elapsed < 10
    end

    test "short TTL expires as expected" do
      # Pass short TTL (50ms)
      {:ok, _html} =
        ETSCache.get_or_render(
          "ExpensiveChart",
          "chart-1",
          %{data: []},
          %{},
          :overwrite,
          MockRenderer,
          ttl: 50
        )

      # Wait longer than TTL
      Process.sleep(100)

      # Should be expired
      # Note: May return :expired_during_wait if entry expires between checks
      result =
        ETSCache.get_or_render(
          "ExpensiveChart",
          "chart-1",
          %{data: []},
          %{},
          :overwrite,
          MockRenderer,
          ttl: 50
        )

      case result do
        {:ok, html} -> assert html == "<div>Chart</div>"
        {:error, :expired_during_wait} -> :ok
      end
    end
  end

  describe "cleanup task" do
    test "cleanup removes expired entries" do
      # Create entries with short TTL
      {:ok, _} =
        ETSCache.get_or_render(
          "Counter",
          "counter-1",
          %{count: 0},
          %{},
          :overwrite,
          MockRenderer,
          ttl: 100
        )

      {:ok, _} =
        ETSCache.get_or_render(
          "Counter",
          "counter-2",
          %{count: 1},
          %{},
          :overwrite,
          MockRenderer,
          ttl: 100
        )

      # Check initial size
      stats = ETSCache.get_stats()
      assert stats.size >= 2

      # Wait for expiration + cleanup interval
      Process.sleep(700)

      # Check size after cleanup
      stats = ETSCache.get_stats()
      # Entries should be cleaned up
      assert stats.size < 2
    end
  end

  describe "Winner/Waiter pattern" do
    test "concurrent requests trigger only one render" do
      # Track render count
      test_pid = self()

      # Create a mock that reports renders
      defmodule ConcurrentMockRenderer do
        def render_component("SlowCounter", _id, _props, _globals, _strategy) do
          # Send message to test process
          send(:test_process, :render_started)
          Process.sleep(200)
          send(:test_process, :render_finished)
          {:ok, "<div>Counter: 0</div>"}
        end
      end

      # Register test process
      Process.register(test_pid, :test_process)

      # Spawn 10 concurrent requests
      tasks =
        for _ <- 1..10 do
          Task.async(fn ->
            ETSCache.get_or_render(
              "SlowCounter",
              "counter-1",
              %{count: 0},
              %{},
              :overwrite,
              ConcurrentMockRenderer
            )
          end)
        end

      # Wait for all tasks
      results = Task.await_many(tasks, 5000)

      # All should succeed
      assert Enum.all?(results, fn {:ok, html} -> html == "<div>Counter: 0</div>" end)

      # Count render messages
      render_count = count_messages(:render_started)

      # Should only render once (Winner/Waiter pattern)
      assert render_count == 1

      # Cleanup
      Process.unregister(:test_process)
    end
  end

  describe "renderer validation" do
    test "validates renderer module exists" do
      assert {:error, {:invalid_renderer, NonExistentModule, _}} =
               ETSCache.get_or_render(
                 "Counter",
                 "counter-1",
                 %{count: 0},
                 %{},
                 :overwrite,
                 NonExistentModule
               )
    end

    test "validates renderer implements render_component/5" do
      defmodule InvalidRenderer do
        # Missing render_component/5
      end

      assert {:error, {:invalid_renderer, InvalidRenderer, :missing_render_component_callback}} =
               ETSCache.get_or_render(
                 "Counter",
                 "counter-1",
                 %{count: 0},
                 %{},
                 :overwrite,
                 InvalidRenderer
               )
    end
  end

  describe "error handling" do
    test "render error is propagated to caller" do
      assert {:error, :render_error} =
               ETSCache.get_or_render(
                 "ErrorComponent",
                 "error-1",
                 %{},
                 %{},
                 :overwrite,
                 MockRenderer
               )
    end

    test "render error does not cache result" do
      # First call - error
      {:error, _} =
        ETSCache.get_or_render(
          "ErrorComponent",
          "error-1",
          %{},
          %{},
          :overwrite,
          MockRenderer
        )

      # Second call - should try to render again (not cached)
      {:error, _} =
        ETSCache.get_or_render(
          "ErrorComponent",
          "error-1",
          %{},
          %{},
          :overwrite,
          MockRenderer
        )

      # Both should fail (error not cached)
    end
  end

  describe "clear_cache" do
    test "clears all cache entries" do
      # Create some cache entries
      {:ok, _} =
        ETSCache.get_or_render(
          "Counter",
          "counter-1",
          %{count: 0},
          %{},
          :overwrite,
          MockRenderer
        )

      {:ok, _} =
        ETSCache.get_or_render(
          "Counter",
          "counter-2",
          %{count: 1},
          %{},
          :overwrite,
          MockRenderer
        )

      # Clear cache
      assert :ok = ETSCache.clear_cache()

      # Check cache is empty
      stats = ETSCache.get_stats()
      assert stats.size == 0
    end
  end

  describe "get_stats" do
    test "returns cache statistics" do
      stats = ETSCache.get_stats()

      assert is_integer(stats.size)
      assert is_integer(stats.memory)
      assert stats.type == :set
    end
  end

  # Helper function to count messages
  defp count_messages(message_type) do
    receive do
      ^message_type -> 1 + count_messages(message_type)
    after
      10 -> 0
    end
  end
end
