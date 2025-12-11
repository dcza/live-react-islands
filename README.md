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
- **`@live-react-islands/core`** (JavaScript/TypeScript) - React hooks and SSR support
- **`live_react_islands_ssr_vite`** (Elixir) - Dev mode SSR Backend using the Vite Dev Server
- **`live_react_islands_ssr_deno`** (Elixir) - Production SSR Backend using a dedicated Deno application
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

React components receive the `pushEvent` function as a prop to send events back to the LiveComponent:

```jsx
function MyComponent({ pushEvent }) {
  const handleClick = () => {
    pushEvent("my_event", { data: "value" });
  };
  // ...
}
```

### Global State

Share state across islands by providing a global store handler when creating the hook.

**Elixir (LiveView):**

```elixir
defmodule MyLiveView do
  use MyAppWeb, :live_view
  use LiveReactIslands.LiveView, globals: [:theme, :user]

  def mount(_params, _session, socket) do
    socket = socket
    |> assign(:theme, "dark")
    |> assign(:user, %{name: "Alice"})

    {:ok, socket}
  end
end
```

**JavaScript (Client Setup):**

```javascript
import { createHooks } from "@live-react-islands/core";
import * as islands from "./islands"; // Import from islands/index.js
import { createStore } from "zustand/vanilla"; // or any store library

// Create your store (store-agnostic)
const store = createStore((set) => ({ theme: "light", user: null }));

// Handler receives global updates from LiveView
const globalStoreHandler = (globals) => {
  store.setState(globals);
};

const hooks = createHooks({
  islands,
  SharedContextProvider: YourContextProvider, // Optional React context wrapper
  globalStoreHandler: globalStoreHandler, // Receives globals from server
});
```

> **Best Practice:** Create an `islands/index.js` file that exports all your islands. This ensures your client and server use the same island map and stay in sync:
>
> ```javascript
> // islands/index.js
> export { default as Counter } from "./Counter";
> export { default as TodoList } from "./TodoList";
> ```

**React (Components):**

```jsx
// Use your own store solution
function MyIsland() {
  const { theme, user } = useStore(); // Your store hook

  return (
    <div className={theme}>
      <h1>Welcome, {user.name}!</h1>
    </div>
  );
}
```

The library is **store-agnostic** - you provide the handler to integrate with your preferred state management solution (Zustand, Redux, Context, etc.).

### Server-Side Rendering (SSR)

LiveReactIslands supports SSR for all major JavaScript runtimes (Deno, Node, Bun).

**1. Create an islands index file (if you haven't already):**

```javascript
// islands/index.js
export { default as Counter } from "./Counter";
export { default as TodoList } from "./TodoList";
```

**2. Client entry point (browser):**

```javascript
// app.js
import { createHooks } from "@live-react-islands/core";
import * as islands from "./islands";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

const hooks = createHooks({ islands });

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...hooks },
});

liveSocket.connect();
```

**3. Server entry point (Deno/Node/Bun):**

```javascript
// ssr.js (for Deno, Node, or Bun)
import { exposeSSR } from "@live-react-islands/core";
import * as islands from "./islands"; // Same islands!

const ContextProvider = ({ children }) => children;

const { renderSSRIslandStatic } = exposeSSR(
  islands,
  ContextProvider,
  (globalState) => console.log(globalState) // Optional
);

// Export for Deno/Node to call
export { renderSSRIslandStatic };
```

> **Note:** Both client and server import from the same `./islands` file, ensuring they stay in sync automatically!

**4. Configure SSR in Elixir:**

```elixir
# config/config.exs
config :your_app, LiveReactIslands,
  main_module_path: "priv/static/assets/ssr.js"
```

**5. Enable SSR in your LiveComponent:**

```elixir
defmodule MyAppWeb.Components.CounterIsland do
  use LiveReactIslands.Component,
    component: "Counter",
    props: %{count: 0},
    ssr_strategy: :overwrite  # or :hydrate_root
end
```

**SSR Strategies:**

- `:none` - No SSR (default), React hydrates on an empty container
- `:overwrite` - SSR renders a preview, React replaces it on mount
- `:hydrate_root` - SSR renders the component, React hydrates the existing DOM

The SSR code is **runtime-agnostic** - the same code works in Deno, Node, Bun, or any JavaScript runtime.

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
