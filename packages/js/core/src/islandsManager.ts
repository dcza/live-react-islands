import React from "react";
import ReactDOM from "react-dom/client";

import {
  ContextProviderComponent,
  IslandData,
  SharedIslandsRendererComponent,
  IndividualIslandsRendererComponent,
  IslandStoreAccess,
  IndividualIslandsRendererProps,
  StreamAction,
  StreamConfig,
} from "./types";
import { PortalIslandsRenderer } from "./PortalIslandsRenderer";
import { IndividualIslandRenderer } from "./IndividualIslandRenderer";

// Constant root ID - one shared root per application
export const SHARED_ROOT_ID = "__live_react_islands_shared_root__";

// ============================================================================
// Types
// ============================================================================

interface ManagerState {
  propsStore: Map<string, Record<string, any>>;
  propsListeners: Set<() => void>;
  globalsRef: React.MutableRefObject<Record<string, any> | null>;
  globalsListeners: Set<() => void>;
  sharedIslandsRef: React.MutableRefObject<Record<string, IslandData>>;
  sharedIslandsListeners: Set<() => void>;
  streamsStore: Map<string, any[]>;
  streamsListeners: Map<string, Set<() => void>>;
  streamConfigs: Map<string, StreamConfig>;
  roots: Record<string, any>;
  storeAccess: IslandStoreAccess;
}

export interface Manager {
  initialize: (params: {
    SharedContextProvider?: ContextProviderComponent;
    SharedIslandsRenderer?: SharedIslandsRendererComponent;
  }) => ManagerState;
  mountIsland: (
    state: ManagerState,
    data: IslandData,
    IslandRenderer?: IndividualIslandsRendererComponent
  ) => ManagerState;
  unmountIsland: (state: ManagerState, id: string) => ManagerState;
  updateIslandProps: (
    state: ManagerState,
    islandId: string,
    props: Record<string, any>
  ) => ManagerState;
  updateGlobals: (
    state: ManagerState,
    globals: Record<string, any>
  ) => ManagerState;
  initializeStream: (
    state: ManagerState,
    islandId: string,
    streamName: string,
    initialItems: any[]
  ) => ManagerState;
  updateStream: (
    state: ManagerState,
    islandId: string,
    streamName: string,
    action: StreamAction,
    data: any
  ) => ManagerState;
}

// ============================================================================
// Helper
// ============================================================================

const NullContextProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => children;

const withSharedRootName = (
  ContextProvider: ContextProviderComponent
): ContextProviderComponent => {
  const originalName =
    ContextProvider.displayName || ContextProvider.name || "ContextProvider";

  function NamedWrapper({ children }: { children: React.ReactNode }) {
    return React.createElement(ContextProvider, null, children);
  }

  NamedWrapper.displayName = `[LiveReactIslands] SharedRoot(${originalName})`;
  return NamedWrapper;
};

const withIndividualRootName = (
  islandId: string,
  IslandRenderer: IndividualIslandsRendererComponent
): IndividualIslandsRendererComponent => {
  const originalName = IslandRenderer.displayName;

  function NamedWrapper(props: IndividualIslandsRendererProps) {
    return React.createElement(IslandRenderer, props);
  }

  NamedWrapper.displayName = `[LiveReactIslands] HydratedRoot#${islandId}`;
  return NamedWrapper;
};

const getOrCreateSharedRootElement = (): HTMLElement => {
  let rootElement = document.getElementById(SHARED_ROOT_ID);
  if (!rootElement) {
    rootElement = document.createElement("div");
    rootElement.id = SHARED_ROOT_ID;
    rootElement.style.display = "none";
    document.body.appendChild(rootElement);
  }
  return rootElement;
};

const mountSharedIsland = (
  state: ManagerState,
  data: IslandData
): ManagerState => {
  state.sharedIslandsRef.current = {
    ...state.sharedIslandsRef.current,
    [data.id]: data,
  };
  state.sharedIslandsListeners.forEach((cb) => cb());
  return state;
};

const mountIndividualIsland = (
  state: ManagerState,
  data: IslandData,
  IslandRenderer: IndividualIslandsRendererComponent
): ManagerState => {
  const NamedIslandRenderer = withIndividualRootName(data.id, IslandRenderer);
  const root = ReactDOM.hydrateRoot(
    data.el,
    React.createElement(
      React.StrictMode,
      null,
      React.createElement(NamedIslandRenderer, {
        data,
        storeAccess: state.storeAccess,
      })
    )
  );

  return {
    ...state,
    roots: { ...state.roots, [data.id]: root },
  };
};

// ============================================================================
// Island Manager (Bridge between LiveView hook lifecycles and React rendering)
// ============================================================================

const ManagerObj: Manager = {
  initialize: ({
    SharedContextProvider = NullContextProvider,
    SharedIslandsRenderer = PortalIslandsRenderer,
  }) => {
    const rootElement = getOrCreateSharedRootElement();
    const root = ReactDOM.createRoot(rootElement);

    const propsStore = new Map<string, Record<string, any>>();
    const propsListeners = new Set<() => void>();
    const globalsRef = { current: null as Record<string, any> | null };
    const globalsListeners = new Set<() => void>();
    const sharedIslandsRef = { current: {} as Record<string, IslandData> };
    const sharedIslandsListeners = new Set<() => void>();
    const streamsStore = new Map<string, any[]>();
    const streamsListeners = new Map<string, Set<() => void>>();
    const streamConfigs = new Map<string, StreamConfig>();

    const getStreamKey = (islandId: string, streamName: string) =>
      `${islandId}:${streamName}`;

    const storeAccess: IslandStoreAccess = {
      getProps: (islandId: string) => propsStore.get(islandId) || null,
      subscribeToProps: (cb: () => void) => {
        propsListeners.add(cb);
        return () => propsListeners.delete(cb);
      },
      getGlobals: () => globalsRef.current,
      subscribeToGlobals: (cb: () => void) => {
        globalsListeners.add(cb);
        return () => globalsListeners.delete(cb);
      },
      getSharedIslands: () => sharedIslandsRef.current,
      subscribeToSharedIslands: (cb: () => void) => {
        sharedIslandsListeners.add(cb);
        return () => sharedIslandsListeners.delete(cb);
      },
      getStreamItems: (islandId: string, streamName: string) => {
        const key = getStreamKey(islandId, streamName);
        return streamsStore.get(key) || [];
      },
      subscribeToStream: (
        islandId: string,
        streamName: string,
        cb: () => void,
        config?: StreamConfig
      ) => {
        const key = getStreamKey(islandId, streamName);
        if (config) {
          streamConfigs.set(key, config);
        }
        if (!streamsListeners.has(key)) {
          streamsListeners.set(key, new Set());
        }
        streamsListeners.get(key)!.add(cb);
        return () => {
          streamsListeners.get(key)?.delete(cb);
          if (streamsListeners.get(key)?.size === 0) {
            streamConfigs.delete(key);
          }
        };
      },
    };

    const state: ManagerState = {
      propsStore,
      globalsRef,
      propsListeners,
      globalsListeners,
      sharedIslandsRef,
      sharedIslandsListeners,
      streamsStore,
      streamsListeners,
      streamConfigs,
      roots: { [SHARED_ROOT_ID]: root },
      storeAccess,
    };

    const NamedSharedContextProvider = withSharedRootName(
      SharedContextProvider
    );

    root.render(
      React.createElement(
        React.StrictMode,
        null,
        React.createElement(
          NamedSharedContextProvider,
          null,
          React.createElement(SharedIslandsRenderer, {
            storeAccess: state.storeAccess,
          })
        )
      )
    );

    return state;
  },
  mountIsland: (state, data, IslandRenderer = IndividualIslandRenderer) => {
    switch (data.ssrStrategy) {
      case "hydrate_root":
        return mountIndividualIsland(state, data, IslandRenderer);
      default:
        return mountSharedIsland(state, data);
    }
  },
  unmountIsland: (state, id) => {
    state.propsStore.delete(id);

    const streamPrefix = `${id}:`;
    for (const key of state.streamsStore.keys()) {
      if (key.startsWith(streamPrefix)) {
        state.streamsStore.delete(key);
        state.streamsListeners.delete(key);
        state.streamConfigs.delete(key);
      }
    }

    if (state.roots[id]) {
      state.roots[id].unmount();
      const { [id]: removedRoot, ...remainingRoots } = state.roots;
      return {
        ...state,
        roots: remainingRoots,
      };
    } else {
      const { [id]: removed, ...remaining } = state.sharedIslandsRef.current;
      state.sharedIslandsRef.current = remaining;
      state.sharedIslandsListeners.forEach((cb) => cb());
      return state;
    }
  },
  updateIslandProps: (state, islandId, props) => {
    const existing = state.propsStore.get(islandId) || {};
    state.propsStore.set(islandId, { ...existing, ...props });
    state.propsListeners.forEach((cb) => cb());
    return state;
  },
  updateGlobals: (state, globals) => {
    const incomingVersion = globals.__version ?? -1;
    const storeVersion = state.globalsRef.current?.__version ?? -1;
    if (incomingVersion > storeVersion) {
      state.globalsRef.current = {
        ...(state.globalsRef.current || {}),
        ...globals,
      };
      state.globalsListeners.forEach((cb) => cb());
    }

    return state;
  },
  initializeStream: (state, islandId, streamName, initialItems) => {
    const key = `${islandId}:${streamName}`;
    state.streamsStore.set(key, [...initialItems]);
    return state;
  },
  updateStream: (state, islandId, streamName, action, data) => {
    const key = `${islandId}:${streamName}`;
    let items = state.streamsStore.get(key) || [];
    const config = state.streamConfigs.get(key);

    switch (action) {
      case StreamAction.Insert:
        items = [data, ...items];
        break;
      case StreamAction.Update:
        const idx = items.findIndex((item) => item.id === data.id);
        if (idx !== -1) {
          items = [...items];
          items[idx] = { ...items[idx], ...data };
        }
        break;
      case StreamAction.Delete:
        items = items.filter((item) => item.id !== data);
        break;
      case StreamAction.Reset:
        items = [];
        break;
    }

    if (config?.capper) {
      items = config.capper(items);
    } else if (config?.limit !== undefined && items.length > config.limit) {
      items = items.slice(0, config.limit);
    }

    state.streamsStore.set(key, items);
    state.streamsListeners.get(key)?.forEach((cb) => cb());
    return state;
  },
};
export default ManagerObj;
