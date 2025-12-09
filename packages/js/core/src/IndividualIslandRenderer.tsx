import React, { ComponentType } from "react";
import { IslandRenderer } from "./IslandRenderer";
import type { IslandComponent, PushEventFn } from "./types";

// ============================================================================
// Individual Island Renderer (wraps IslandRenderer with context for individual roots)
// ============================================================================

interface IndividualIslandRendererProps {
  Component: IslandComponent;
  props: Record<string, any>;
  id: string;
  pushEvent: PushEventFn;
  ContextProvider: ComponentType<{ children: React.ReactNode }>;
}

export const IndividualIslandRenderer: React.FC<
  IndividualIslandRendererProps
> = ({ Component, props, id, pushEvent, ContextProvider }) => {
  return (
    <ContextProvider>
      <IslandRenderer
        Component={Component}
        props={props}
        id={id}
        pushEvent={pushEvent}
      />
    </ContextProvider>
  );
};
