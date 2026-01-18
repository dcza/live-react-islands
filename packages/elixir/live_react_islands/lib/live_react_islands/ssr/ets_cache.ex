defmodule LiveReactIslands.SSR.ETSCache do
  @moduledoc """
  ETS-backed cache implementation for SSR rendering.

  Uses the Winner/Waiter pattern for performance and thundering herd protection:

  - **Cache hits**: Direct ETS read (~1-2 microseconds, no GenServer overhead)
  - **Cache misses**: Atomic lock via `:ets.insert_new/2` prevents duplicate renders
  - **Winner**: First process to acquire lock renders and caches result
  - **Waiters**: Other processes poll ETS for winner's result
  - **GenServer**: Only used for cleanup, stats, and configuration (never in hot path)

  ## Configuration

      config :live_react_islands,
        ssr_cache: LiveReactIslands.SSR.ETSCache,
        cache_default_ttl: :timer.minutes(5),
        cache_cleanup_interval: :timer.minutes(1)

  ## Opt-In Caching

  Caching is opt-in per component. Components must explicitly enable caching:

      # Simple opt-in with defaults
      defmodule MyApp.Components.ProductCard do
        use LiveReactIslands.Component,
          component: "ProductCard",
          ssr_strategy: :overwrite,
          ssr_cache: true  # Uses default TTL from config
      end

      # Custom cache options
      defmodule MyApp.Components.ExpensiveChart do
        use LiveReactIslands.Component,
          component: "ExpensiveChart",
          ssr_strategy: :overwrite,
          ssr_cache: [ttl: :timer.minutes(10), id_in_key: true]
      end

      # Not cached (no ssr_cache option)
      defmodule MyApp.Components.OtherComponent do
        use LiveReactIslands.Component,
          component: "OtherComponent",
          ssr_strategy: :overwrite
      end

  Cache options:

      ssr_cache: true                       # Enable with defaults
      ssr_cache: [
        ttl: :timer.minutes(10),            # Override default TTL
        id_in_key: true,                    # Boolean: include ID in cache key?
        ssr_props: %{},                     # Override props for SSR (shell caching)
        ssr_globals: %{},                   # Override globals for SSR (shell caching)
        cache_key_fn: &my_key_fn/5          # Custom cache key function (advanced)
      ]

  ## Shell Caching (Skeleton SSR)

  You can cache a "shell" or "skeleton" by providing placeholder data for SSR:

      defmodule MyApp.Components.UserProfile do
        use LiveReactIslands.Component,
          component: "UserProfile",
          ssr_strategy: :hydrate_root,
          ssr_cache: [
            ttl: :timer.minutes(10),
            ssr_props: %{email: "", name: "Loading..."}  # Placeholders for SSR
          ]
      end

  The component renders with placeholder data (cached), but the real data is pushed to the client and rendered in a second pass after hydration is completed (to prevent hydration mismatches). This allows caching the HTML structure
  while supporting user-specific data.

  ## Performance Characteristics

  - Cache hit latency: 1-2 microseconds (direct ETS lookup)
  - Thundering herd: 500 requests → 1 render + 499 waits
  - No GenServer bottleneck on render path
  - Atomic locking prevents duplicate renders
  - Read concurrency enabled for parallel cache lookups
  """

  use GenServer
  require Logger

  @behaviour LiveReactIslands.SSR.Cache

  @pending_timeout :timer.seconds(30)
  @poll_interval 50

  defstruct [:cleanup_timer]

  ## Public API

  @doc """
  Start the cache GenServer.

  ## Options

  - `:default_ttl` - Default time-to-live in milliseconds (default: 5 minutes)
  - `:cleanup_interval` - How often to cleanup expired entries (default: 1 minute)

  Component-specific cache options are configured on the component itself via the `ssr_cache` option.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl LiveReactIslands.SSR.Cache
  def get_or_render(component_name, id, props, globals, ssr_strategy, renderer_module, opts \\ []) do
    case validate_renderer_module(renderer_module) do
      :ok ->
        cache_key = generate_cache_key(component_name, id, props, globals, opts)

        get_or_render_with_lock(
          cache_key,
          component_name,
          id,
          props,
          globals,
          ssr_strategy,
          renderer_module,
          opts
        )

      {:error, reason} ->
        {:error, {:invalid_renderer, renderer_module, reason}}
    end
  end

  @impl LiveReactIslands.SSR.Cache
  def clear_cache do
    GenServer.call(__MODULE__, :clear_cache)
  end

  @impl LiveReactIslands.SSR.Cache
  def clear_cache(_component_name) do
    GenServer.call(__MODULE__, :clear_cache)
  end

  @impl LiveReactIslands.SSR.Cache
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  ## GenServer Callbacks

  @impl true
  def init(opts) do
    :ets.new(:live_react_islands_ssr_cache, [
      :set,
      :public,
      :named_table,
      read_concurrency: true
    ])

    cleanup_interval =
      Keyword.get(opts, :cleanup_interval) ||
        Application.get_env(:live_react_islands, :cache_cleanup_interval, :timer.minutes(1))

    timer = Process.send_after(self(), :cleanup_expired, cleanup_interval)

    Logger.info(
      "SSR cache: LiveReactIslands.SSR.ETSCache started (cleanup interval: #{cleanup_interval}ms)"
    )

    {:ok, %__MODULE__{cleanup_timer: timer}}
  end

  @impl true
  def handle_call(:clear_cache, _from, state) do
    :ets.delete_all_objects(:live_react_islands_ssr_cache)
    Logger.info("SSR cache cleared")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    info = :ets.info(:live_react_islands_ssr_cache)

    stats = %{
      size: info[:size],
      memory: info[:memory],
      type: info[:type]
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_info(:cleanup_expired, state) do
    now = System.monotonic_time(:millisecond)
    # Only match entries with numeric expiration (skip :infinity entries)
    match_spec = [{{:"$1", {:"$2", :"$3"}}, [{:andalso, {:is_integer, :"$3"}, {:<, :"$3", now}}], [true]}]

    deleted = :ets.select_delete(:live_react_islands_ssr_cache, match_spec)

    if deleted > 0 do
      Logger.debug("SSR cache cleanup: removed #{deleted} expired entries")
    end

    cleanup_interval =
      Application.get_env(:live_react_islands, :cache_cleanup_interval, :timer.minutes(1))

    timer = Process.send_after(self(), :cleanup_expired, cleanup_interval)

    {:noreply, %{state | cleanup_timer: timer}}
  end

  @impl true
  def terminate(_reason, state) do
    if state.cleanup_timer do
      Process.cancel_timer(state.cleanup_timer)
    end

    :ets.delete(:live_react_islands_ssr_cache)
    :ok
  end

  ## Private Functions

  defp get_or_render_with_lock(
         cache_key,
         component_name,
         id,
         props,
         globals,
         ssr_strategy,
         renderer_module,
         opts
       ) do
    now = System.monotonic_time(:millisecond)

    case :ets.lookup(:live_react_islands_ssr_cache, cache_key) do
      [{^cache_key, {html, :infinity}}] ->
        {:ok, html}

      [{^cache_key, {html, expires_at}}] when is_integer(expires_at) and expires_at > now ->
        {:ok, html}

      _ ->
        case :ets.insert_new(:live_react_islands_ssr_cache, {cache_key, :pending}) do
          true ->
            winner_render_and_store(
              cache_key,
              component_name,
              id,
              props,
              globals,
              ssr_strategy,
              renderer_module,
              opts
            )

          false ->
            waiter_poll_for_result(cache_key, @pending_timeout)
        end
    end
  end

  defp winner_render_and_store(
         cache_key,
         component_name,
         id,
         props,
         globals,
         ssr_strategy,
         renderer_module,
         opts
       ) do
    case renderer_module.render_component(component_name, id, props, globals, ssr_strategy) do
      {:ok, html} ->
        expires_at =
          case Keyword.get(opts, :ttl) do
            :infinity ->
              :infinity

            ttl when is_integer(ttl) ->
              System.monotonic_time(:millisecond) + ttl

            nil ->
              default_ttl =
                Application.get_env(:live_react_islands, :cache_default_ttl, :timer.minutes(5))

              System.monotonic_time(:millisecond) + default_ttl
          end

        :ets.insert(:live_react_islands_ssr_cache, {cache_key, {html, expires_at}})

        {:ok, html}

      {:error, _reason} = error ->
        :ets.delete(:live_react_islands_ssr_cache, cache_key)
        error
    end
  end

  defp waiter_poll_for_result(cache_key, timeout) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_poll(cache_key, deadline)
  end

  defp do_poll(cache_key, deadline) do
    now = System.monotonic_time(:millisecond)

    if now >= deadline do
      :ets.delete(:live_react_islands_ssr_cache, cache_key)
      {:error, :render_timeout}
    else
      case :ets.lookup(:live_react_islands_ssr_cache, cache_key) do
        [{^cache_key, {html, _expires_at}}] ->
          {:ok, html}

        [{^cache_key, :pending}] ->
          Process.sleep(@poll_interval)
          do_poll(cache_key, deadline)

        [] ->
          {:error, :render_failed}
      end
    end
  end

  defp generate_cache_key(component_name, id, props, globals, opts) do
    case Keyword.get(opts, :cache_key_fn) do
      fun when is_function(fun, 5) ->
        terms = fun.(component_name, id, props, globals, opts)
        hash_key_terms(terms)

      nil ->
        id_in_key = Keyword.get(opts, :id_in_key, false)

        terms =
          if id_in_key do
            {component_name, id, props, globals}
          else
            {component_name, props, globals}
          end

        hash_key_terms(terms)
    end
  end

  defp hash_key_terms(terms) do
    :crypto.hash(:sha256, :erlang.term_to_binary(terms))
    |> Base.encode16()
  end

  defp validate_renderer_module(module) when is_atom(module) do
    case Code.ensure_loaded(module) do
      {:module, ^module} ->
        if function_exported?(module, :render_component, 5) do
          :ok
        else
          {:error, :missing_render_component_callback}
        end

      {:error, reason} ->
        {:error, {:module_not_loaded, reason}}
    end
  end

  defp validate_renderer_module(_), do: {:error, :invalid_module}
end
