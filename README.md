# Live React Islands

**React-powered interactive islands** inside Phoenix LiveView. Harness the NPM ecosystem with server-driven state, real-time streams and zero-lag forms + SSR.

![Banner](https://raw.githubusercontent.com/dcza/live-react-islands/main/docs/repository-open-graph.png)

## Why Live React Islands?

**The best of both worlds!** ✨

Phoenix LiveView is excellent for server-driven UIs, but sometimes you need the rich interactivity of React for specific components. Live React Islands lets you:

- Use React components as "islands" within your LiveView templates
- Maintain server-side state in Elixir while rendering in React
- Send events from React to Elixir and push props back
- Use forms and streams in React with dedicated hooks
- Share global state across multiple islands
- Optionally server-side render for faster loads, SEO and no flicker

## Comparison

Choose Live React Islands when you need rich, interactive React components without giving up LiveView’s server-driven simplicity.

| Feature                | LiveView Only                              | LiveView + Alpine    | Live React Islands (this)              | Pure SPA (Next.js/Vite) |
| :--------------------- | :----------------------------------------- | :------------------- | :------------------------------------- | :---------------------- |
| **UI Ecosystem**       | Limited (HEEX/Custom)                      | Small (Alpine kits)  | **Infinite (NPM/React)**               | **Infinite (NPM)**      |
| **Interactivity**      | Server-Roundtrip (JS hooks for edge cases) | Simple Client-side   | **High-Fidelity / Fluid**              | High-Fidelity / Fluid   |
| **State Management**   | Single (Server)                            | Fragmented           | **Single (Server-Led)**                | Dual (API + Client)     |
| **Initial Load / SEO** | Instant                                    | Instant              | **Instant (SSR-enabled)**              | Slow / Complex SSR      |
| **JS Bundle Size**     | ~0kb (Core only)                           | Small (+15kb)        | **Large (React: ~100–150 kB gzipped)** | Large                   |
| **Developer Speed**    | Very High                                  | High (until complex) | **High (Asset Reuse)**                 | Low (API Plumbing)      |
| **Component Logic**    | Elixir Only                                | Mixed (Strings)      | **JSX (Encapsulated)**                 | JSX                     |
| **Complexity Ceiling** | Struggles with app-like complexity         | Hits wall on "State" | **High**                               | Very High               |

## When NOT to Use Live React Islands

- If your UI is mostly static or CRUD-heavy, plain LiveView is simpler and faster.
- If you only need light client-side behavior (toggles, dropdowns), LiveView + Alpine may be sufficient.
- If your application requires full offline support or heavy client-side state, a traditional SPA may be a better fit.

## Installation

### Elixir

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:live_react_islands, "~> 0.1.0"},
    # For development SSR (optional):
    {:live_react_islands_ssr_vite, "~> 0.1.0", only: :dev},
    # For production SSR (optional):
    {:live_react_islands_ssr_deno, "~> 0.1.0", only: :prod}
  ]
end
```

### JavaScript

```bash
npm install @live-react-islands/core
# For development SSR (optional):
npm install --save-dev @live-react-islands/vite-plugin-ssr
```

## Quick Start

### 1. Create a React Component

```jsx
// src/islands/Counter.jsx
const Counter = ({ count, title, pushEvent }) => {
  return (
    <div>
      <h2>{title}</h2>
      <p>Count: {count}</p>
      <button onClick={() => pushEvent("increment", {})}>+1</button>
    </div>
  );
};

export default Counter;
```

### 2. Set Up the LiveView Hooks

```jsx
// src/islands/index.js
export default { Counter: () => import("./Counter") };
```

Islands can be lazy loaded to only load the JS used on the page.

```jsx
// src/main.jsx
import { createHooks } from "@live-react-islands/core";
import islands from "./islands";

const islandHooks = createHooks({ islands });

// Add to your LiveSocket
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...islandHooks },
});
```

### 3. Create an Elixir Component

```elixir
defmodule MyAppWeb.Components.CounterIsland do
  use LiveReactIslands.Component,
    component: "Counter",
    props: %{count: 0, title: "My Counter"}

  def handle_event("increment", _params, socket) do
    new_count = socket.assigns.count + 1
    {:noreply, update_prop(socket, :count, new_count)}
  end
end
```

### 4. Use in Your LiveView

```elixir
defmodule MyAppWeb.CounterLive do
  use MyAppWeb, :live_view
  use LiveReactIslands.LiveView

  def render(assigns) do
    ~H"""
    <.live_component module={MyAppWeb.Components.CounterIsland} id="counter-1" />
    """
  end
end
```

## How It Works

**React components receive these props automatically:**

| Prop                 | Description                       |
| -------------------- | --------------------------------- |
| `id`                 | The island's unique identifier    |
| `pushEvent`          | Function to send events to Elixir |
| All defined props    | Current values from Elixir        |
| All consumed globals | Current global state values       |

## Features

### Props

Define props with default values. Props can be set from the template or updated from event handlers:

```elixir
use LiveReactIslands.Component,
  component: "Counter",
  props: %{count: 0, title: "Default Title"}
```

**Elixir components can override `init/2` for dynamic initialization:**

```elixir
def init(assigns, socket) do
  # Called once on mount, before SSR and first render
  socket
  |> update_prop(:computed, compute_value(assigns))
end
```

**Updating props from Elixir:**

```elixir
def handle_event("increment", _, socket) do
  {:noreply, update_prop(socket, :count, socket.assigns.count + 1)}
end
```

**Passing props from templates:**

```heex
<.live_component module={CounterIsland} id="counter-1" title="Custom Title" />
```

Once a prop is set from outside the component any `update_prop` call on it will raise an error to prevent a nasty set of bugs. To just initialize the component use `init_[prop]` to set the value once and then the component takes over.

```heex
<.live_component module={CounterIsland} id="counter-1" init_count={5} />
```

### Events

Send events from React to Elixir using `pushEvent`:

```jsx
// React
<button onClick={() => pushEvent("save", { data: formData })}>Save</button>
```

```elixir
# Elixir
def handle_event("save", %{"data" => data}, socket) do
  # Handle the event
  {:noreply, socket}
end
```

### Global State

Share state across multiple islands. When a global changes, all islands that use it automatically rerender.

**Set up in your LiveView:**

```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view
  use LiveReactIslands.LiveView, expose_globals: [:user, :theme]

  def mount(_params, session, socket) do
    {:ok, assign(socket, user: get_user(session), theme: "light")}
  end
end
```

**Consume in your island:**

```elixir
use LiveReactIslands.Component,
  component: "Header",
  props: %{},
  globals: [:user, :theme]
```

**Optional globals** (won't error if not set):

```elixir
globals: [:user?]  # The ? suffix makes it optional
```

The globals are passed as props to your React component:

```jsx
const Header = ({ user, theme }) => (
  <header className={theme}>Welcome, {user.name}</header>
);
```

### Forms with Server Validation

Build forms with React UI and Elixir/Ecto validation. Input is collected client side with zero typing latency and send to Elixir for validation. Errors from the changeset get pushed back to React.

The `useForm` hook implements a "Validation Lock" pattern: Updates are versioned and `isValid` will only be true until the server confirms the current form state is valid.

**Elixir component:**

```elixir
defmodule MyAppWeb.Components.ContactFormIsland do
  use LiveReactIslands.Component,
    component: "ContactForm",
    props: %{form: %{}}

  alias MyApp.Contact

  def init(_assigns, socket) do
    changeset = Contact.changeset(%Contact{}, %{})
    socket |> init_form(:form, changeset)
  end

  def handle_form(:validate, :form, attrs, socket) do
    changeset = Contact.changeset(%Contact{}, attrs)
    {:noreply, update_form(socket, :form, changeset)}
  end

  def handle_form(:submit, :form, attrs, socket) do
    case Contact.create(attrs) do
      {:ok, _contact} ->
        {:noreply, init_form(socket, :form, Contact.changeset(%Contact{}, %{}))}
      {:error, changeset} ->
        {:noreply, update_form(socket, :form, changeset)}
    end
  end
end
```

**React component:**

```jsx
import { useForm } from "@live-react-islands/core";

const ContactForm = ({ form, pushEvent }) => {
  const {
    getFieldProps,
    getError,
    isRequired,
    isTouched,
    handleSubmit,
    isValid,
  } = useForm(form, pushEvent);

  return (
    <form onSubmit={handleSubmit}>
      <input {...getFieldProps("name")} />
      {isTouched("name") && getError("name") && (
        <span className="error">{getError("name")}</span>
      )}

      <input {...getFieldProps("email")} type="email" />
      {isTouched("email") && getError("email") && (
        <span className="error">{getError("email")}</span>
      )}

      <button type="submit" disabled={!isValid}>
        Submit
      </button>
    </form>
  );
};
```

**`useForm` returns:**

| Property                | Description                                           |
| ----------------------- | ----------------------------------------------------- |
| `values`                | Current form values                                   |
| `errors`                | Validation errors by field                            |
| `touched`               | Fields the user has interacted with                   |
| `getFieldProps(name)`   | Props to spread on inputs (`value`, `onChange`, etc.) |
| `getError(name)`        | First error message for a field                       |
| `isRequired(name)`      | Whether a field is required                           |
| `isTouched(name)`       | Whether user has modified this field                  |
| `setField(name, value)` | Programmatically set a field value                    |
| `handleSubmit`          | Form submit handler                                   |
| `reset()`               | Reset form to server values                           |
| `isSyncing`             | True while waiting for server validation              |
| `isValid`               | True only when synced AND server says valid           |

### Streams

Stream data to React components for real-time updates like feeds, chat, or infinite scrolling:

**Define a stream prop:**

```elixir
use LiveReactIslands.Component,
  component: "MessageList",
  props: %{
    messages: {:stream, default: []}
  }
```

**Push stream events from Elixir:**

```elixir
# Insert new item (prepends by default)
socket |> stream_insert(:messages, %{id: 1, text: "Hello"})

# Update existing item
socket |> stream_update(:messages, %{id: 1, text: "Hello, edited"})

# Delete an item
socket |> stream_delete(:messages, 1)

# Reset the entire stream
socket |> stream_reset(:messages)
```

**Consume in React:**

```jsx
import { useStream } from "@live-react-islands/core";

const MessageList = ({ messages: messagesHandle }) => {
  const messages = useStream(messagesHandle, { limit: 100 });

  return (
    <ul>
      {messages.map((msg) => (
        <li key={msg.id}>{msg.text}</li>
      ))}
    </ul>
  );
};
```

### Shared Context

Islands using `:none` (default) or `:overwrite` SSR strategies render into a shared React root via portals. This enables powerful patterns like drag-and-drop between islands, shared state managers, or animation libraries that need to coordinate across components.

**Wrap all islands in a shared context:**

```jsx
// src/main.jsx
import { createHooks } from "@live-react-islands/core";
import { DndProvider } from "react-beautiful-dnd";
import islands from "./islands";

const SharedContextProvider = ({ children }) => (
  <DndProvider backend={HTML5Backend}>{children}</DndProvider>
);

const islandHooks = createHooks({
  islands,
  SharedContextProvider,
});
```

Now all your islands can participate in drag-and-drop with each other, even though they're scattered across your LiveView template.

> **Note:** Islands using `:hydrate_root` SSR strategy have their own isolated React root and do not participate in the shared context. Use `:overwrite` or `:none` if you need context sharing between islands.

### Server-Side Rendering (SSR)

SSR improves initial page load performance by rendering React components on the server.

```elixir
use LiveReactIslands.Component,
  component: "Counter",
  props: %{count: 0},
  ssr_strategy: :overwrite  # or :hydrate_root or :none (default)
```

| Strategy        | Shared Root | Best For                                                                |
| --------------- | ----------- | ----------------------------------------------------------------------- |
| `:none`         | Yes         | Interactive components where initial render doesn't matter              |
| `:overwrite`    | Yes         | Most islands, especially when you need cross-island context (e.g., DnD) |
| `:hydrate_root` | No          | Large islands where you want to avoid the overwrite flash               |

> ⚠️ SSR is optional. Many islands work perfectly without it. Enable SSR when initial paint, SEO, or perceived performance matter.

See the **[SSR Guide](https://raw.githubusercontent.com/dcza/live-react-islands/main/docs/SSR.md)** for complete setup instructions, caching strategies, and custom renderer implementation.

## Requirements

- Elixir >= 1.14
- Phoenix LiveView >= 1.0
- React 18 or 19
- Any JavaScript bundler (built-in SSR plugin for Vite)

### Running Examples

```bash
cd examples/vite-example
mix deps.get
yarn install
yarn dev
mix phx.server  # in another terminal
```

## Contributing

See [CONTRIBUTING.md](https://raw.githubusercontent.com/dcza/live-react-islands/main/CONTRIBUTING.md) for development setup and guidelines.

## License

MIT License - see [LICENSE](https://raw.githubusercontent.com/dcza/live-react-islands/main/LICENSE) for details.
