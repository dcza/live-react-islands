import { ComponentType } from "react";

// ============================================================================
// Core Types
// ============================================================================

export type IslandsMap = Record<string, IslandComponent | IslandConfig>;

export type IslandComponent = ComponentType<any>;

export type ContextProviderComponent = ComponentType<{
  children: React.ReactNode;
}>;

export interface IslandConfig {
  Component: IslandComponent;
  ContextProvider?: ContextProviderComponent;
}

export type SSRStrategy = "none" | "overwrite" | "hydrate_root";

export type PushEventFn = (eventName: string, payload: any) => void;

export interface IslandData {
  id: string;
  el: HTMLElement;
  ssrStrategy: SSRStrategy;
  Component: IslandComponent;
  ContextProvider?: ContextProviderComponent;
  props: Record<string, any>;
  pushEvent: PushEventFn;
}

export interface SharedIslandsRendererProps {
  onReady?: () => void;
}

export interface SharedIslandsRendererHandle {
  setRenderingEnabled: (enabled: boolean) => void;
  addIsland: (data: IslandData) => void;
  updateIsland: (id: string, props: Record<string, any>) => void;
  removeIsland: (id: string) => void;
}

export type SharedIslandsRendererComponent = React.ForwardRefExoticComponent<
  SharedIslandsRendererProps & React.RefAttributes<SharedIslandsRendererHandle>
>;
