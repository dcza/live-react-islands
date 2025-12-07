# LiveReactIslands

> **⚠️ Work in Progress**: This project is currently under active development and is not intended for public use yet.

**React Islands for Phoenix LiveView** - Embed React components in LiveView with bidirectional communication, server-side rendering, and global state management.

## Demo

![Demo](docs/demo01.gif)

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
┌────────────────────────────────────────────────────────────────┐
│                      Phoenix LiveView                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ LiveComponent    │  │ LiveComponent    │  │ LiveComponent│  │
│  │ (Counter)        │  │ (TodoList)       │  │ (MyIsland)   │  │
│  └────────┬─────────┘  └────────┬─────────┘  └──────┬───────┘  │
│           │ props ↓             │                   │          │
│           │ events ↑            │                   │          │
└───────────┼─────────────────────┼───────────────────┼──────────┘
            │                     │                   │
            ▼                     ▼                   ▼
  ┌─────────────────────────────────────────────────────────────┐
  │              LiveView Hook (JavaScript)                     │
  │  ┌──────────────────────────────────────────────────────┐   │
  │  │          Single React Root (createRoot)              │   │
  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │   │
  │  │  │   Portal    │  │   Portal    │  │   Portal    │   │   │
  │  │  │  <Counter>  │  │  <TodoList> │  │  <MyIsland> │   │   │
  │  │  └─────────────┘  └─────────────┘  └─────────────┘   │   │
  │  └──────────────────────────────────────────────────────┘   │
  └─────────────────────────────────────────────────────────────┘
```

## Packages

This monorepo contains:

- **`live_react_islands`** (Elixir) - Phoenix LiveView integration
- **`@live-react-islands/core`** (JavaScript/TypeScript) - React hooks and utilities
- **`examples/with-esbuild`** - Example using esbuild bundler
- **`examples/with-vite`** - Example using Vite bundler

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
npm install @live-react-islands/core react react-dom
# or
yarn add @live-react-islands/core react react-dom
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
      <button onClick={() => pushEvent("increment", {})}>Increment</button>
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
    <.live_component module={MyAppWeb.Components.CounterIsland} id="counter" />
    """
  end
end
```

## Key Concepts

### Prop Ownership

LiveReactIslands tracks which component "owns" each prop:

- **Internal Owned**: LiveComponent manages the prop (LiveComponent → React)
- **External Owned**: LiveView manages the prop, passed down through LiveComponent (LiveView → LiveComponent → React)

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

Share state across islands by providing a global store handler when creating the hook.

**Elixir (LiveView):**

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

**JavaScript (Hook Setup):**

```javascript
import { createIslandsHook } from '@live-react-islands/core';
import { createStore } from 'zustand/vanilla'; // or any store library

// Create your store (store-agnostic)
const store = createStore((set) => ({ theme: 'light', user: null }));

// Handler receives global updates from LiveView
const globalStoreHandler = (globals) => {
  store.setState(globals);
};

export default createIslandsHook(
  { Counter, TodoList },
  YourContextProvider,     // Optional React context wrapper
  globalStoreHandler       // Receives globals from server
);
```

**React (Components):**

```jsx
// Use your own store solution
function MyIsland() {
  const { theme, user } = useStore();  // Your store hook

  return (
    <div className={theme}>
      <h1>Welcome, {user.name}!</h1>
    </div>
  );
}
```

The library is **store-agnostic** - you provide the handler to integrate with your preferred state management solution (Zustand, Redux, Context, etc.).

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
cd examples/with-esbuild  # or examples/with-vite
mix deps.get
yarn install
yarn watch  # or yarn dev for Vite
# In another terminal:
mix phx.server
```

## Contributing

Contributions are welcome! Please read our [Contributing Guide](./CONTRIBUTING.md) for details.

## License

MIT License - see [LICENSE](./LICENSE) for details.

## Credits

Created by David Czaplinski

Inspired by the islands architecture pattern and existing Phoenix-React integration libraries.
