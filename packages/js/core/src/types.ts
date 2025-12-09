import { ComponentType } from "react";

// ============================================================================
// Core Types
// ============================================================================

export type IslandsMap = Record<string, IslandComponent | IslandConfig>;
export type IslandComponent = ComponentType<any>;
export interface IslandConfig {
  component: IslandComponent;
  ContextProvider?: ComponentType<{ children: React.ReactNode }>;
}

export interface State {
  roots: Record<string, any>;
  sharedRootRef: React.RefObject<SharedRootHandle> | null;
}

export type SSRStrategy = "none" | "overwrite" | "hydrate_root";
export type PushEventFn = (eventName: string, payload: any) => void;

// ============================================================================
// Island Data
// ============================================================================

export interface IslandData {
  id: string;
  Component: IslandComponent;
  props: Record<string, any>;
  el: HTMLElement;
  pushEvent: PushEventFn;
}

// ============================================================================
// Registry & Handle
// ============================================================================

export interface SharedRootRegistry {
  addIsland?: (data: IslandData) => void;
  updateIsland?: (data: { id: string; props: Record<string, any> }) => void;
  removeIsland?: (id: string) => void;
}

export interface SharedRootHandle {
  setGlobalsReady: (ready: boolean) => void;
  registry: SharedRootRegistry;
}

// ============================================================================
// Manager Interface
// ============================================================================

export interface Manager {
  initialize: (
    islandsMap: IslandsMap,
    SharedContextProvider: ComponentType<{ children: React.ReactNode }>
  ) => State;
  mountIsland: (state: State, params: MountIslandParams) => State;
  unmountIsland: (state: State, params: UnmountIslandParams) => State;
  updateIslandProps: (state: State, params: UpdateIslandPropsParams) => void;
  enableRendering: (state: State) => void;
}

// ============================================================================
// Function Parameters
// ============================================================================

export interface MountIslandParams {
  element: HTMLElement;
  componentName: string;
  ssrStrategy: SSRStrategy;
  defaultContextProvider: ComponentType<{ children: React.ReactNode }>;
  pushEvent: PushEventFn;
}

export interface UnmountIslandParams {
  islandElementId: string;
}

export interface UpdateIslandPropsParams {
  islandElementId: string;
  props: Record<string, any>;
}
