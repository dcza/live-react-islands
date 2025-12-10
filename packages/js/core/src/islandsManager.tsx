import React, { ComponentType } from "react";
import ReactDOM from "react-dom/client";

import type {
  Manager,
  IslandsMap,
  IslandComponent,
  MountIslandParams,
  PushEventFn,
  UnmountIslandParams,
  ContextProviderComponenet,
  ManagerState,
} from "./types";
import {
  PortalIslandsRenderer,
  PortalIslandsRendererHandle,
} from "./PortalIslandsRenderer";

const ManagerMock: Manager = {
  initialize: ({ SharedContextProvider }) => {
    const rootElement = getOrCreateSharedRootElement();
    const root = ReactDOM.createRoot(rootElement);
    const sharedRendererRef = React.createRef<PortalIslandsRendererHandle>();
    root.render(
      <SharedContextProvider>
        <PortalIslandsRenderer ref={sharedRendererRef} />
      </SharedContextProvider>
    );
    return {
      roots: { [SHARED_ROOT_ID]: root },
      sharedRendererRef,
    };
  },
  mountIsland: (state, params) => state,
  unmountIsland: (state, params) => state,
  updateIslandProps: (state, params) => {},
  enableRendering: (state) => {},
};
export default ManagerMock;

// Constant root ID - one shared root per application
export const SHARED_ROOT_ID = "__live_react_islands_shared_root__";

// ============================================================================
// Pure Helper Functions
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

// ============================================================================
// Root Management
// ============================================================================

export const createIndividualRoot = (
  element: HTMLElement,
  IndividualRendererComponent: ComponentType<any>,
  rendererProps: any
): ReactDOM.Root => {
  console.log(
    "[createIndividualRoot] Creating individual root for:",
    element.id
  );

  const shouldHydrate = needsHydration(element);

  const content = React.createElement(
    IndividualRendererComponent,
    rendererProps
  );

  if (shouldHydrate) {
    return ReactDOM.hydrateRoot(element, content);
  } else {
    const root = ReactDOM.createRoot(element);
    root.render(content);
    return root;
  }
};

// ============================================================================
// Render Control
// ============================================================================

export const enableRendering = (state: ManagerState): void => {
  if (state.sharedRootRef?.current) {
    state.sharedRootRef.current.setGlobalsReady(true);
  }
};

// ============================================================================
// Island Mounting
// ============================================================================

export const mountSharedIsland = (
  element: HTMLElement,
  Component: IslandComponent,
  props: Record<string, any>,
  pushEvent: PushEventFn,
  state: ManagerState
): void => {
  const addIslandWhenReady = () => {
    if (state.sharedRootRef?.current?.registry?.addIsland) {
      state.sharedRootRef.current.registry.addIsland({
        id: element.id,
        Component,
        props,
        el: element,
        pushEvent,
      });
    } else {
      console.log("[mountSharedIsland] Waiting for root to be ready...");
      setTimeout(addIslandWhenReady, 10);
    }
  };

  addIslandWhenReady();
};

export const mountIndividualIsland = (
  element: HTMLElement,
  Component: IslandComponent,
  props: Record<string, any>,
  ContextProvider: ContextProviderComponenet,
  pushEvent: PushEventFn,
  IndividualRendererComponent: ComponentType<any>
): ReactDOM.Root => {
  return createIndividualRoot(element, IndividualRendererComponent, {
    Component,
    props,
    id: element.id,
    pushEvent,
    ContextProvider,
  });
};

// ============================================================================
// Island Lifecycle
// ============================================================================

export const mountIsland = (params: MountIslandParams): MountResult | null => {
  const {
    element,
    componentName,
    islandComponents,
    defaultContextProvider,
    pushEvent,
    globalState,
    IslandRendererComponent,
  } = params;

  // Get component config
  const config = extractIslandConfig(islandComponents, componentName);

  if (!config) {
    console.error(`[mountIsland] Component '${componentName}' not found`);
    element.innerHTML = `<div style="color: red; padding: 10px; border: 1px solid red;">
      Error: Island component '${componentName}' not found
    </div>`;
    return null;
  }

  const { Component, ContextProvider: IslandContextProvider } = config;
  const FinalContextProvider = IslandContextProvider || defaultContextProvider;

  // Decide root type
  const shouldUseIndividualRoot =
    element.dataset.ssrStrategy === "hydrate_root";

  const props = {};

  if (shouldUseIndividualRoot) {
    const root = mountIndividualIsland(
      element,
      Component,
      props,
      FinalContextProvider,
      pushEvent,
      IslandRendererComponent
    );
    return { rootType: "individual", root };
  } else {
    mountSharedIsland(element, Component, props, pushEvent, globalState);
    return { rootType: "shared" };
  }
};

export const unmountIsland = (params: UnmountIslandParams): void => {
  const { elementId, rootType, root, globalState } = params;

  console.log("[unmountIsland] Unmounting:", elementId, rootType);

  if (rootType === "individual" && root) {
    root.unmount();
  } else if (rootType === "shared") {
    globalState.sharedRootRef?.current?.registry?.removeIsland?.(elementId);
  }
};

export const updateSharedIslandProps = (
  elementId: string,
  props: Record<string, any>,
  state: ManagerState
): void => {
  state.sharedRootRef?.current?.registry?.updateIsland?.({
    id: elementId,
    props,
  });
};

// ============================================================================
// Navigation & Cleanup
// ============================================================================

export const cleanupAllRoots = (state: ManagerState): void => {
  console.log("[cleanupAllRoots] Cleaning up shared root");
  if (state.roots[SHARED_ROOT_ID]) {
    state.roots[SHARED_ROOT_ID].unmount();
    delete state.roots[SHARED_ROOT_ID];
  }
  // Clear ref
  state.sharedRootRef = null;
};

export const handleNavigation = (
  currentNavigationCounter: number,
  globalState: ManagerState
): boolean => {
  const navigationOccurred =
    globalState.lastNavigationCounter !== undefined &&
    globalState.lastNavigationCounter !== currentNavigationCounter;

  if (navigationOccurred) {
    console.log("[handleNavigation] Navigation detected, cleaning up");
    cleanupAllRoots(globalState);
    return true;
  }

  return false;
};

// ============================================================================
// Global State Factory
// ============================================================================

export const createState = (): ManagerState => ({
  roots: {},
  sharedRootRegistry: {},
  globalsReady: false,
  setGlobalsReady: undefined,
  lastNavigationCounter: undefined,
});

// ============================================================================
// Initialization
// ============================================================================

export const initializeSharedRoot = (
  ContextProvider: ContextProviderComponenet,
  globalState: ManagerState,
  IslandsRootComponent: ComponentType<any>,
  registryRef: React.RefObject<any>
): void => {
  if (!globalState.roots[SHARED_ROOT_ID]) {
    createSharedRootWithPortals(
      ContextProvider,
      globalState,
      IslandsRootComponent,
      registryRef
    );
  }
};

// ============================================================================
// Hook Lifecycle Logic
// ============================================================================

export interface HookMountParams {
  element: HTMLElement;
  componentName: string;
  islandComponents: IslandsMap;
  defaultContextProvider: ContextProviderComponenet;
  pushEvent: PushEventFn;
  globalState: ManagerState;
  navigationCounter: number;
  globalsRequested: boolean;
  globalStoreHandler: ((data: any) => void) | null;
  onGlobalsRequest: (
    handler: (data: any) => void,
    onUpdate: (data: any) => void
  ) => void;
}

export interface HookMountResult {
  mountResult: MountResult | null;
  navigationDetected: boolean;
  globalsNowRequested: boolean;
}

export const mountIslandAndHandleNavigation = (
  params: HookMountParams
): HookMountResult => {
  const {
    element,
    componentName,
    islandComponents,
    defaultContextProvider,
    pushEvent,
    globalState,
    navigationCounter,
    globalsRequested,
    globalStoreHandler,
    onGlobalsRequest,
  } = params;

  console.log("[mountIslandAndHandleNavigation] Mounting:", element.id);

  // Handle navigation cleanup
  const navigationDetected = handleNavigation(navigationCounter, globalState);

  globalState.lastNavigationCounter = navigationCounter;

  // Handle global store request
  let globalsNowRequested = globalsRequested;
  if (!globalsRequested && globalStoreHandler) {
    globalsNowRequested = true;
    onGlobalsRequest(globalStoreHandler, (data: any) =>
      globalStoreHandler(data)
    );
  }

  // Mount the island
  const mountResult = mountIsland({
    element,
    componentName,
    islandComponents,
    defaultContextProvider,
    pushEvent,
    globalState,
  });

  return {
    mountResult,
    navigationDetected,
    globalsNowRequested,
  };
};

export const updateIslandProps = (
  elementId: string,
  props: Record<string, any>,
  rootType: "shared" | "individual",
  globalState: ManagerState
): void => {
  if (rootType === "shared") {
    updateSharedIslandProps(elementId, props, globalState);
  }
  // TODO: Individual roots don't support prop updates yet
};
