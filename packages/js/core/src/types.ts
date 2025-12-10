import { ComponentType } from "react";
import { PortalIslandsRendererHandle } from "./PortalIslandsRenderer";

// ============================================================================
// Core Types
// ============================================================================

export type IslandsMap = Record<string, IslandComponent | IslandConfig>;
export type IslandComponent = ComponentType<any>;
export type ContextProviderComponenet = ComponentType<{
  children: React.ReactNode;
}>;
export interface IslandConfig {
  Component: IslandComponent;
  ContextProvider?: ContextProviderComponenet;
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

export interface ManagerState {
  roots: Record<string, any>;
  sharedRendererRef: React.RefObject<PortalIslandsRendererHandle>;
}

export interface Manager {
  initialize: (params: {
    SharedContextProvider: ContextProviderComponenet;
  }) => ManagerState;
  mountIsland: (state: ManagerState, params: MountIslandParams) => ManagerState;
  unmountIsland: (
    state: ManagerState,
    params: UnmountIslandParams
  ) => ManagerState;
  updateIslandProps: (
    state: ManagerState,
    params: UpdateIslandPropsParams
  ) => void;
  enableRendering: (state: ManagerState) => void;
}

// ============================================================================
// Function Parameters
// ============================================================================

export interface MountIslandParams {
  element: HTMLElement;
  islandConfig: IslandConfig;
  ssrStrategy: SSRStrategy;
  pushEvent: PushEventFn;
}

export interface UnmountIslandParams {
  islandElementId: string;
}

export interface UpdateIslandPropsParams {
  islandElementId: string;
  props: Record<string, any>;
}
