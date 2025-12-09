import React, { ComponentType, memo, useRef } from "react";
import type { IslandComponent, PushEventFn } from "./types";

// ============================================================================
// Island Renderer (renders a single island component)
// ============================================================================

interface IslandRendererProps {
  Component: IslandComponent;
  props: Record<string, any>;
  id: string;
  pushEvent: PushEventFn;
}

export const IslandRenderer: React.FC<IslandRendererProps> = ({
  Component,
  props,
  id,
  pushEvent,
}) => {
  const memoizedComponentsRef = useRef(
    new Map<IslandComponent, ComponentType<any>>()
  );

  // Memoize component to prevent unnecessary re-renders
  if (!memoizedComponentsRef.current.has(Component)) {
    memoizedComponentsRef.current.set(Component, memo(Component));
  }
  const MemoizedComponent = memoizedComponentsRef.current.get(Component)!;

  return <MemoizedComponent {...props} id={id} pushEvent={pushEvent} />;
};
