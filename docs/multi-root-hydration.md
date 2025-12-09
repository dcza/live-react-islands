# Multi-Root Hydration Strategy

## Overview

Live React Islands supports multiple rendering strategies that can be mixed within the same application:

1. **Shared Root (Default)**: Multiple islands share a single React root via portals, enabling efficient context sharing
2. **Shared Root with SSR (Overwrite)**: Islands use the shared root but can display server-rendered HTML that gets replaced on mount
3. **Hydrate Root (SSR)**: Individual islands get their own React root, enabling true server-side rendering with hydration

## Architecture

### Shared Root Strategy (Default)

```
┌─────────────────────────────────────┐
│   Single Hidden React Root          │
│   ┌─────────────────────────────┐   │
│   │   <AppContextProvider>      │   │
│   │     <IslandsRoot>           │   │
│   │       Portal → Stats        │   │
│   │       Portal → UserMenu     │   │
│   │       Portal → Sidebar      │   │
│   │     </IslandsRoot>          │   │
│   │   </AppContextProvider>     │   │
│   └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Characteristics:**
- One React root for multiple islands
- Islands rendered via React portals
- Context shared across all islands
- Client-side rendering (can show SSR content that gets replaced)
- Efficient for many small interactive components

### Shared Root with SSR (Overwrite Strategy)

```
┌─────────────────────────────────────┐
│   Single Hidden React Root          │
│   ┌─────────────────────────────┐   │
│   │   <AppContextProvider>      │   │
│   │     <IslandsRoot>           │   │
│   │       Portal → Stats        │   │
│   │       Portal → UserMenu     │   │
│   │     </IslandsRoot>          │   │
│   └─────────────────────────────┘   │
└─────────────────────────────────────┘

Island DOM (before mount):
<div id="stats">
  <!-- SSR content here -->
  <div>Loading: 42 users</div>
</div>

Island DOM (after mount):
<div id="stats">
  <!-- React portal content (replaced SSR) -->
  <div>Live: 42 users</div>
</div>
```

**Characteristics:**
- Same shared root architecture as default
- Server renders initial HTML into island containers
- On mount, React clears the SSR content and renders via portal
- Context shared across all islands (same instance)
- Good for SEO and initial paint, but SSR content is discarded (no hydration)
- Often sufficient for small islands that benefit from initial content

### Hydrate Root Strategy (SSR)

```
┌──────────────────────┐  ┌──────────────────────┐
│ Island Root 1        │  │ Island Root 2        │
│ ┌──────────────────┐ │  │ ┌──────────────────┐ │
│ │ <ContextProvider>│ │  │ │ <ContextProvider>│ │
│ │   <CheckoutForm> │ │  │ │   <BlogPost>     │ │
│ │   </CheckoutForm>│ │  │ │   </BlogPost>    │ │
│ │ </ContextProvider│ │  │ │ </ContextProvider│ │
│ └──────────────────┘ │  │ └──────────────────┘ │
└──────────────────────┘  └──────────────────────┘
```

**Characteristics:**
- Each island instance gets its own React root
- True hydration of server-rendered HTML (preserves DOM, attaches events)
- Context isolated per island (separate instances)
- Supports SSR with proper hydration
- Ideal for large, complex components where hydration benefits matter

## When to Use Each Strategy

### Use Shared Root (Default) When:
- Building many small interactive islands (buttons, menus, stats cards)
- Islands need to share state via React context
- Client-side rendering is sufficient
- No initial content needed
- Performance matters (single root is more efficient)

### Use Shared Root with SSR (Overwrite) When:
- Small islands that benefit from initial content (SEO, perceived performance)
- Context sharing is important (same instance across islands)
- Don't need true hydration (discarding SSR content is acceptable)
- Want to keep the simple shared root architecture
- **Most common SSR use case for small islands**

### Use Hydrate Root When:
- Component is large and complex (full forms, rich editors, data tables)
- True hydration benefits matter (preserving user input, scroll position, etc.)
- Component is mostly self-contained
- Don't need context sharing with other islands
- Worth the cost of isolated context per island

### Mixed Strategy Example

A typical app might use all three strategies:

```elixir
# 1. Client-only islands (no SSR)
<div id="user-menu" data-component="UserMenu" phx-hook="LiveReactIslands" />

# 2. Small islands with SSR (overwrite strategy - shared root)
<div id="header" data-component="Header" phx-hook="LiveReactIslands">
  <%= render_react_ssr(Header, %{user: @current_user}) %>
</div>

<div id="stats" data-component="Stats" phx-hook="LiveReactIslands">
  <%= render_react_ssr(Stats, %{count: @user_count}) %>
</div>

# 3. Large island with true hydration (individual root)
<div id="checkout-form"
     data-component="CheckoutForm"
     data-ssr-strategy="hydrate_root"
     phx-hook="LiveReactIslands">
  <%= render_react_ssr(CheckoutForm, %{items: @cart_items}) %>
</div>
```

## Configuration

### Client-Side (JavaScript)

```tsx
import { createHooks } from '@live-react-islands/core';
import AppContextProvider from './contexts/AppContext';
import CheckoutContextProvider from './contexts/CheckoutContext';

// Import island components
import Header from './islands/Header';
import Stats from './islands/Stats';
import Sidebar from './islands/Sidebar';
import CheckoutForm from './islands/CheckoutForm';

const hooks = createHooks({
  islands: {
    // Default: uses shared root
    Header: Header,
    Stats: Stats,
    Sidebar: Sidebar,

    // Override context for specific island
    CheckoutForm: {
      component: CheckoutForm,
      ContextProvider: CheckoutContextProvider, // Optional override
    },
  },

  // Default context provider for all islands
  ContextProvider: AppContextProvider,
});

export default hooks;
```

### Server-Side (Elixir)

```elixir
# Strategy 1: Client-only (no SSR)
def render(assigns) do
  ~H"""
  <div id="my-island"
       data-component="MyComponent"
       phx-hook="LiveReactIslands">
  </div>
  """
end

# Strategy 2: SSR with overwrite (shared root)
def render(assigns) do
  ~H"""
  <div id="my-ssr-island"
       data-component="MyComponent"
       phx-hook="LiveReactIslands">
    <%= render_react_ssr(MyComponent, @props) %>
  </div>
  """
end

# Strategy 3: SSR with hydration (individual root)
def render(assigns) do
  ~H"""
  <div id="my-hydrating-island"
       data-component="MyComponent"
       data-ssr-strategy="hydrate_root"
       phx-hook="LiveReactIslands">
    <%= render_react_ssr(MyComponent, @props) %>
  </div>
  """
end
```

## Context Behavior

### Shared Root Islands (Default and Overwrite SSR)

All islands in the shared root see the **same context instance**, regardless of whether they use SSR overwrite or not:

```tsx
// AppContextProvider wraps the entire islands root
// Stats (with SSR) and UserMenu (client-only) share the same context state
<AppContextProvider>
  <IslandsRoot>
    {createPortal(<Stats />, statsElement)}      // Had SSR, got overwritten
    {createPortal(<UserMenu />, menuElement)}    // Client-only
    {createPortal(<Header />, headerElement)}    // Had SSR, got overwritten
  </IslandsRoot>
</AppContextProvider>
```

**Key point**: SSR overwrite strategy doesn't change context behavior. Islands still share context because they use the same root.

### Hydrate Root Islands

Each hydrating island gets its **own context instance**:

```tsx
// First checkout form instance
hydrateRoot(element1,
  <AppContextProvider>
    <CheckoutForm />
  </AppContextProvider>
);

// Second checkout form instance
hydrateRoot(element2,
  <AppContextProvider>
    <CheckoutForm />
  </AppContextProvider>
);
```

**Important**: Context providers for hydrating islands must be designed to sync via external mechanisms if state sharing is needed:
- External state management (Zustand, Jotai, etc.)
- LocalStorage/SessionStorage
- URL parameters
- Server state via LiveView

## Implementation Notes

### Detection Logic

The hook detects the rendering strategy via the `data-ssr-strategy` attribute:

```javascript
mounted() {
  const { component, ssrStrategy } = this.el.dataset;

  if (ssrStrategy === 'hydrate_root') {
    // Strategy 3: Create individual root with ReactDOM.hydrateRoot()
    // Preserves SSR HTML and attaches React event handlers
  } else {
    // Strategy 1 & 2: Add to shared root via portal
    // If element has SSR content, it gets cleared and replaced (overwrite)
    // If element is empty, React just renders (client-only)
  }
}
```

### Root Lifecycle

**Shared Root:**
- Created once on page load
- Persists across island mounts/unmounts
- Cleaned up on navigation

**Hydrate Roots:**
- Created per island instance on mount
- Unmounted when island is destroyed
- Independent lifecycle from other islands

## Limitations

### Cannot Hydrate Multiple Islands in One Root

Due to React's hydration model, you cannot hydrate multiple disconnected DOM elements from a single React root. Portals cannot be used with hydration.

**This does NOT work:**
```tsx
// ❌ Cannot hydrate portals to multiple elements
hydrateRoot(
  hiddenRoot,
  <>
    {createPortal(<Island1 />, element1)}
    {createPortal(<Island2 />, element2)}
  </>
);
```

**This works:**
```tsx
// ✅ Each island gets its own root
hydrateRoot(element1, <Island1 />);
hydrateRoot(element2, <Island2 />);
```

### Context Isolation with Hydration

When using `data-ssr-strategy="hydrate_root"`, understand that:
- Each island instance has isolated context
- Context providers must handle their own state synchronization
- Changes in one island's context do not affect others
- This is by design and cannot be avoided with hydration

## Migration Path

### Starting Simple (Shared Root Only)

Most applications should start with the shared root approach:

```tsx
createHooks({
  islands: { Header, Stats, UserMenu },
  ContextProvider: AppContext,
});
```

### Adding SSR Incrementally

**Step 1: Start with SSR Overwrite (Shared Root)**

Most components should start here:

1. Identify components that benefit from initial content (SEO, perceived performance)
2. Add server-side rendering to those islands (no `data-ssr-strategy` needed)
3. Islands keep shared context, SSR content gets replaced on mount
4. Simple and efficient for most use cases

```elixir
# Just add SSR content, no strategy attribute needed
<div id="stats" data-component="Stats" phx-hook="LiveReactIslands">
  <%= render_react_ssr(Stats, %{count: @user_count}) %>
</div>
```

**Step 2: Upgrade to Hydrate Root (Only When Needed)**

Only use this for large, complex islands where true hydration benefits matter:

1. Identify the few large islands that need true hydration
2. Add `data-ssr-strategy="hydrate_root"` to those specific islands
3. Optionally provide island-specific context providers
4. Document context isolation for your team
5. Ensure context providers sync via external mechanisms if needed

```elixir
# Only for large islands that benefit from hydration
<div id="checkout"
     data-component="CheckoutForm"
     data-ssr-strategy="hydrate_root"
     phx-hook="LiveReactIslands">
  <%= render_react_ssr(CheckoutForm, %{items: @cart_items}) %>
</div>
```

**Rule of thumb**: Use SSR overwrite (shared root) for 90% of islands. Only use hydrate root for the few large, complex islands where it truly matters.

## Future Considerations

- **Concurrent Rendering**: Leverage React 18's concurrent features within large hydrating islands for better perceived performance
- **Lazy Island Loading**: Code-split island components and load them on-demand to reduce initial bundle size
- **Per-Island SSR Caching**: Flexible caching strategies per island type:
  - Static islands (e.g., marketing content): aggressive caching
  - User-specific islands (e.g., personalized feeds): cache per-user or skip caching
  - Session-aware islands (e.g., auth status): cache by session type
  - Real-time islands (e.g., live counters): no caching
- **Dev Tools**: Better debugging for multi-root scenarios (visualize which islands use which roots, context inspection)
- **Partial Hydration Hints**: Allow marking parts of large islands as static to reduce hydration cost

## Sharing State Between Hydrated Islands

If you need to share state between islands using `hydrate_root` (which have isolated contexts), use external state management solutions:

```tsx
// Use Zustand, Jotai, or similar
import { create } from 'zustand';

const useSharedStore = create((set) => ({
  user: null,
  setUser: (user) => set({ user }),
}));

// Each island's context can read from the same store
function AppContextProvider({ children }) {
  const { user, setUser } = useSharedStore();
  return <AppContext.Provider value={{ user, setUser }}>{children}</AppContext.Provider>;
}
```

This is standard React patterns - no framework-specific helpers needed.
