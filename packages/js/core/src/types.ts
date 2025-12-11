import { ComponentType } from "react";

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

export interface IslandData {
  id: string;
  el: HTMLElement;
  ssrStrategy: SSRStrategy;
  Component: IslandComponent;
  ContextProvider?: ContextProviderComponenet;
  props: Record<string, any>;
  pushEvent: PushEventFn;
}
