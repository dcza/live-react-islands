import React from "react";
import ReactDOM from "react-dom/client";

import type {
  ContextProviderComponent,
  IslandData,
  SharedIslandsRendererComponent,
  SharedIslandsRendererHandle,
} from "./types";
import { PortalIslandsRenderer } from "./PortalIslandsRenderer";

// Constant root ID - one shared root per application
export const SHARED_ROOT_ID = "__live_react_islands_shared_root__";

// ============================================================================
// Types
// ============================================================================

interface ManagerState {
  renderingEnabled: boolean;
  roots: Record<string, any>;
  individualRendererRefs: Record<string, any>;
  sharedRendererRef: React.RefObject<SharedIslandsRendererHandle>;
  pendingSharedIslands: IslandData[];
}

export interface Manager {
  initialize: (params: {
    SharedContextProvider: ContextProviderComponent;
    SharedIslandsRenderer?: SharedIslandsRendererComponent;
  }) => ManagerState;
  mountIsland: (state: ManagerState, data: IslandData) => ManagerState;
  unmountIsland: (state: ManagerState, id: string) => ManagerState;
  updateIslandProps: (
    state: ManagerState,
    id: string,
    props: Record<string, any>
  ) => void;
  enableRendering: (state: ManagerState) => ManagerState;
}

// ============================================================================
// Helper
// ============================================================================

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

const flushPendingIslands = (state: ManagerState): void => {
  console.log(
    `[IslandsManager] Flushing ${state.pendingSharedIslands.length} pending islands`
  );
  state.pendingSharedIslands.forEach((data) => {
    state.sharedRendererRef.current?.addIsland(data);
  });
  state.pendingSharedIslands = [];
};

const mountSharedIsland = (state: ManagerState, data: IslandData): void => {
  if (state.sharedRendererRef.current) {
    state.sharedRendererRef.current.addIsland(data);
  } else {
    console.log(`[Island(${data.id})] Queueing until renderer ready`);
    state.pendingSharedIslands.push(data);
  }
};

// ============================================================================
// Island Manager (Bridge between LiveView hook lifecycles and React rendering)
// ============================================================================

const ManagerObj: Manager = {
  initialize: ({
    SharedContextProvider,
    SharedIslandsRenderer = PortalIslandsRenderer,
  }) => {
    const rootElement = getOrCreateSharedRootElement();
    const root = ReactDOM.createRoot(rootElement);
    const sharedRendererRef = React.createRef<SharedIslandsRendererHandle>();

    const state: ManagerState = {
      renderingEnabled: false,
      roots: { [SHARED_ROOT_ID]: root },
      individualRendererRefs: {},
      sharedRendererRef,
      pendingSharedIslands: [],
    };

    root.render(
      React.createElement(
        SharedContextProvider,
        null,
        React.createElement(SharedIslandsRenderer, {
          ref: sharedRendererRef,
          onReady: () => {
            console.log("[IslandsManager] Shared renderer ready");
            flushPendingIslands(state);
          },
        })
      )
    );

    return state;
  },
  enableRendering: (state) => {
    state.sharedRendererRef.current?.setRenderingEnabled(true);
    Object.keys(state.individualRendererRefs).forEach((key) =>
      state.individualRendererRefs[key].current?.setRenderingEnabled(true)
    );
    return { ...state, renderingEnabled: true };
  },
  mountIsland: (state, data) => {
    switch (data.ssrStrategy) {
      case "hydrate_root":
        //TODO: Create and hydrate individual root
        return state;
      default:
        mountSharedIsland(state, data);
        return state;
    }
  },
  updateIslandProps: (state, id, props) => {
    if (state.individualRendererRefs[id])
      state.individualRendererRefs[id].current?.update(props);
    else {
      state.sharedRendererRef.current?.updateIsland(id, props);
    }
  },
  unmountIsland: (state, id) => {
    if (state.roots[id]) {
      state.roots[id].unmount();
      const { [id]: removed, ...remainingRoots } = state.roots;
      return { ...state, roots: remainingRoots };
    } else {
      state.sharedRendererRef.current?.removeIsland(id);
      return state;
    }
  },
};
export default ManagerObj;
