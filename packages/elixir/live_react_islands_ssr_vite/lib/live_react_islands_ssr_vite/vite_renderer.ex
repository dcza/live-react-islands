defmodule LiveReactIslands.SSR.ViteRenderer do
  @moduledoc """
  Vite dev server SSR renderer implementation using HTTP.

  Implements the LiveReactIslands.SSR.Renderer behaviour to provide
  server-side rendering of React components via Vite's dev server.

  This renderer is designed for development mode and communicates with
  a Vite dev server running the SSR middleware plugin.
  """
  @behaviour LiveReactIslands.SSR.Renderer
  use GenServer
  require Logger

  @default_timeout 5000
  @default_vite_url "http://127.0.0.1:5173"

  defstruct [:vite_url, :timeout]

  @doc """
  Starts the ViteRenderer GenServer.

  ## Options

  - `:vite_url` - URL of the Vite dev server (default: #{@default_vite_url})
  - `:timeout` - Request timeout in milliseconds (default: #{@default_timeout})

  ## Examples

      # Start with defaults
      {:ok, _pid} = LiveReactIslands.SSR.ViteRenderer.start_link()

      # Start with custom URL
      {:ok, _pid} = LiveReactIslands.SSR.ViteRenderer.start_link(vite_url: "http://localhost:3000")
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def render_component(component_name, id, props, global_state, strategy) do
    GenServer.call(
      __MODULE__,
      {:render_component, component_name, id, props, global_state, strategy},
      @default_timeout + 1000
    )
  end

  @impl true
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl true
  def init(opts) do
    vite_url = Keyword.get(opts, :vite_url, @default_vite_url)
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    state = %__MODULE__{
      vite_url: vite_url,
      timeout: timeout
    }

    Logger.info("SSR renderer: LiveReactIslands.SSR.ViteRenderer started, connecting to #{vite_url}")

    case Req.get("#{vite_url}/__ssr") do
      {:ok, _} ->
        Logger.info("SSR renderer: Successfully connected to Vite dev server")

      {:error, error} ->
        Logger.warning("SSR renderer: Could not connect to Vite dev server at #{vite_url}: #{inspect(error)}")
    end

    {:ok, state}
  end

  @impl true
  def handle_call(
        {:render_component, component_name, id, props, global_state, strategy},
        _from,
        state
      ) do
    url = "#{state.vite_url}/__ssr"

    js_strategy =
      case strategy do
        :hydrate_root -> "hydrate_root"
        :overwrite -> "overwrite"
        _ -> "overwrite"
      end

    body = %{
      component: component_name,
      id: id,
      props: props,
      globals: global_state,
      strategy: js_strategy
    }

    result =
      Req.post(url,
        json: body,
        receive_timeout: state.timeout,
        retry: false
      )

    case result do
      {:ok, %{status: 200, body: %{"html" => html}}} ->
        {:reply, {:ok, html}, state}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Vite SSR error (#{status}): #{inspect(body)}")
        error_msg = extract_error_message(body, "SSR failed with status #{status}")
        {:reply, {:error, error_msg}, state}

      {:error, %{reason: :econnrefused}} ->
        Logger.error("Vite SSR: Connection refused to #{url}")
        {:reply, {:error, "Vite dev server not running at #{state.vite_url}"}, state}

      {:error, %{reason: :timeout}} ->
        Logger.error("Vite SSR: Request timeout for #{component_name}")
        {:reply, {:error, "SSR request timeout"}, state}

      {:error, reason} ->
        Logger.error("Vite SSR request failed: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      vite_url: state.vite_url,
      timeout: state.timeout,
      renderer_type: :vite
    }

    {:reply, stats, state}
  end

  # Helper function to extract error message from response body
  defp extract_error_message(body, _default) when is_binary(body), do: body

  defp extract_error_message(%{"error" => error}, _default) when is_binary(error),
    do: error

  defp extract_error_message(%{"message" => message}, _default) when is_binary(message),
    do: message

  defp extract_error_message(_body, default), do: default
end
