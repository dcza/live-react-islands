# LiveReactIslands

**React Islands for Phoenix LiveView** - Embed React components in LiveView with bidirectional communication, server-side rendering, and global state management.

## Features

- **Seamless Integration**: Embed React components directly in Phoenix LiveView with minimal setup
- **Bidirectional Communication**: Props flow from LiveView to React, events flow from React to LiveView
- **Server-Side Rendering**: Optional SSR with caching for improved performance
- **Global State Management**: Share state across multiple islands on the same page
- **Prop Ownership Tracking**: Intelligent handling of internal vs external prop updates
- **Single React Root**: Efficient resource usage with React portals
- **TypeScript Support**: Full type definitions for the React package

## Architecture

LiveReactIslands provides a bridge between Phoenix LiveView (Elixir backend) and React (JavaScript frontend):

```
┌─────────────────────────────────────────────────────────────┐
│                     Phoenix LiveView                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ React Island │  │ React Island │  │ React Island │     │
│  │  Component   │  │  Component   │  │  Component   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         ▲                  ▲                  ▲             │
│         │ props/events     │                  │             │
│         ▼                  ▼                  ▼             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │           Single React Root (Portals)               │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Packages

This monorepo contains:

- **`live_react_islands`** (Elixir) - Phoenix LiveView integration
- **`@live_react_islands/react`** (JavaScript/TypeScript) - React hooks and utilities
- **`examples/basic-demo`** - Basic usage example

## Quick Start

### Installation

**Elixir (mix.exs):**
```elixir
def deps do
  [
    {:live_react_islands, "~> 0.1.0"}
  ]
end
```

**JavaScript:**
```bash
npm install @live_react_islands/react react react-dom
# or
yarn add @live_react_islands/react react react-dom
```

### Configuration

**config/config.exs:**
```elixir
config :your_app, LiveReactIslands,
  main_module_path: "priv/static/assets/ssr.js"
```

### Basic Usage

**1. Create a React Island Component (Elixir):**

```elixir
defmodule MyAppWeb.Components.CounterIsland do
  use LiveReactIslands.Component,
    component: "Counter",
    props: %{count: 0},
    ssr_strategy: :none

  def handle_event("increment", _params, socket) do
    new_count = socket.assigns.count + 1
    {:noreply, socket |> update_prop(:count, new_count)}
  end
end
```

**2. Create the React Component:**

```jsx
// assets/js/components/Counter.jsx
export default function Counter({ count, pushEvent }) {
  return (
    <div>
      <h2>Count: {count}</h2>
      <button onClick={() => pushEvent("increment", {})}>
        Increment
      </button>
    </div>
  );
}
```

**3. Use it in your LiveView:**

```elixir
defmodule MyAppWeb.PageLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.live_component module={MyAppWeb.Components.CounterIsland} id="counter" count={@count} />
    """
  end
end
```

## Key Concepts

### Prop Ownership

LiveReactIslands tracks which side "owns" each prop:

- **Internal Owned** (LiveView → React): LiveView is the source of truth
- **External Owned** (React → LiveView): React controls the value, LiveView receives updates

### Event Communication

React components receive `pushEvent` and `pushEventTo` functions as props to send events back to LiveView:

```jsx
function MyComponent({ pushEvent }) {
  const handleClick = () => {
    pushEvent("my_event", { data: "value" });
  };
  // ...
}
```

### Server-Side Rendering

Enable SSR for better initial load performance:

```elixir
use LiveReactIslands.Component,
  component: "MyComponent",
  props: %{},
  ssr_strategy: :override_ssr  # or :none
```

### Global State

Share state across islands using the Globals macro:

```elixir
defmodule MyLiveView do
  use MyAppWeb, :live_view
  use LiveReactIslands.Globals

  def mount(_params, _session, socket) do
    socket = socket
    |> assign_global(:theme, "dark")
    |> assign_global(:user, %{name: "Alice"})

    {:ok, socket}
  end
end
```

## Comparison with Other Libraries

| Feature | LiveReactIslands | phoenix_islands | phoenix_live_react |
|---------|------------------|-----------------|-------------------|
| Prop Ownership Tracking | ✅ | ❌ | ❌ |
| Server-Side Rendering | ✅ (DenoRider) | ❌ | ✅ (Basic) |
| Global State Management | ✅ | ❌ | ❌ |
| Macro-based API | ✅ | ❌ | ❌ |
| Single React Root | ✅ | ❌ | ❌ |
| TypeScript Support | ✅ | ⚠️ | ⚠️ |

## Documentation

- [Getting Started Guide](./docs/getting-started.md)
- [API Reference - Elixir](./packages/elixir/live_react_islands/README.md)
- [API Reference - React](./packages/react/README.md)
- [Examples](./examples/)

## Development

### Setup

```bash
# Clone the repository
git clone https://github.com/live_react_islands/live-react-islands.git
cd live-react-islands

# Install JavaScript dependencies
yarn install

# Build packages
yarn build
```

### Running Examples

```bash
cd examples/basic-demo
mix deps.get
mix phx.server
```

## Contributing

Contributions are welcome! Please read our [Contributing Guide](./CONTRIBUTING.md) for details.

## License

MIT License - see [LICENSE](./LICENSE) for details.

## Credits

Created by David Czaplinski

Inspired by the islands architecture pattern and existing Phoenix-React integration libraries.
