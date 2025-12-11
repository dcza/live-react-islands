import React from "react";
import ReactDOM from "react-dom/client";

import type { ContextProviderComponent, IslandData } from "./types";
import {
  PortalIslandsRenderer,
  PortalIslandsRendererHandle,
} from "./PortalIslandsRenderer";

// Constant root ID - one shared root per application
export const SHARED_ROOT_ID = "__live_react_islands_shared_root__";

// ============================================================================
// Types
// ============================================================================

interface ManagerState {
  renderingEnabled: boolean;
  roots: Record<string, any>;
  individualRendererRefs: Record<string, any>;
  sharedRendererRef: React.RefObject<PortalIslandsRendererHandle>;
}

export interface Manager {
  initialize: (params: {
    SharedContextProvider: ContextProviderComponent;
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

const mountSharedIsland = (state: ManagerState, data: IslandData): void => {
  const addIslandWhenReady = () => {
    if (state.sharedRendererRef.current?.addIsland) {
      state.sharedRendererRef.current.addIsland(data);
    } else {
      console.log(`[Island(${data.id})] Waiting for root to be ready...`);
      setTimeout(addIslandWhenReady, 10);
    }
  };
  addIslandWhenReady();
};

// ============================================================================
// Island Manager (Bridge between LiveView hook lifecycles and React rendering)
// ============================================================================

const ManagerObj: Manager = {
  initialize: ({ SharedContextProvider }) => {
    const rootElement = getOrCreateSharedRootElement();
    const root = ReactDOM.createRoot(rootElement);
    const sharedRendererRef = React.createRef<PortalIslandsRendererHandle>();
    root.render(
      React.createElement(
        SharedContextProvider,
        null,
        React.createElement(PortalIslandsRenderer, { ref: sharedRendererRef })
      )
    );
    return {
      renderingEnabled: false,
      roots: { [SHARED_ROOT_ID]: root },
      individualRendererRefs: {},
      sharedRendererRef,
    };
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
