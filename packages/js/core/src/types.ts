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

export interface StreamConfig {
  limit?: number;
  capper?: (items: any[]) => any[];
}

export interface IslandStoreAccess {
  getProps: (islandId: string) => Record<string, any> | null;
  subscribeToProps: (callback: () => void) => () => void;
  getGlobals: () => Record<string, any> | null;
  subscribeToGlobals: (callback: () => void) => () => void;
  getSharedIslands: () => Record<string, IslandData>;
  subscribeToSharedIslands: (callback: () => void) => () => void;
  getStreamItems: (islandId: string, streamName: string) => any[];
  subscribeToStream: (
    islandId: string,
    streamName: string,
    callback: () => void,
    config?: StreamConfig
  ) => () => void;
}

export enum StreamAction {
  Insert = "i",
  Update = "u",
  Delete = "d",
  Reset = "r",
}

export interface StreamHandle {
  name: string;
  initial: any[];
}

export interface IslandData {
  id: string;
  el: HTMLElement;
  ssrStrategy: SSRStrategy;
  Component: IslandComponent;
  ContextProvider?: ContextProviderComponent;
  hydrationData: {
    props: Record<string, any>;
    globals: Record<string, any>;
  } | null;
  pushEvent: PushEventFn;
  globalKeys: string[];
}

export interface SharedIslandsRendererProps {
  storeAccess: IslandStoreAccess;
}
export type SharedIslandsRendererComponent =
  React.FC<SharedIslandsRendererProps>;

export interface IndividualIslandsRendererProps {
  data: IslandData;
  storeAccess: IslandStoreAccess;
}
export type IndividualIslandsRendererComponent =
  React.FC<IndividualIslandsRendererProps>;

export const NullContextProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => children;
