import React, { useState, useRef, useImperativeHandle, forwardRef } from "react";
import { createPortal } from "react-dom";
import type { IslandData, SharedRootRegistry } from "./types";
import { IslandRenderer } from "./IslandRenderer";

// ============================================================================
// Portal Islands Renderer (renders islands via portals in shared root)
// ============================================================================

interface PortalIslandsRendererProps {
  globalsReady: boolean;
}

export interface PortalIslandsRendererHandle {
  setGlobalsReady: (ready: boolean) => void;
  registry: SharedRootRegistry;
}

export const PortalIslandsRenderer = forwardRef<
  PortalIslandsRendererHandle,
  PortalIslandsRendererProps
>(({ globalsReady: initialGlobalsReady }, ref) => {
  const [globalsReady, setGlobalsReady] = useState(initialGlobalsReady);
  const [islands, setIslands] = useState<Record<string, IslandData>>({});
  const clearedElements = useRef(new Set<string>());

  // Expose methods via ref
  useImperativeHandle(ref, () => ({
    setGlobalsReady,
    registry: {
      addIsland: (data: IslandData) => {
        console.log("[PortalIslandsRenderer] Adding island:", data.el.id);
        setIslands((prev) => ({
          ...prev,
          [data.el.id]: data,
        }));
      },
      updateIsland: ({ id, props }) => {
        setIslands((prev) => ({
          ...prev,
          [id]: { ...prev[id], props: { ...prev[id]?.props, ...props } },
        }));
      },
      removeIsland: (id: string) => {
        setIslands((prev) => {
          const newState = { ...prev };
          delete newState[id];
          return newState;
        });
      },
    },
  }));

  if (!globalsReady) {
    console.log("[PortalIslandsRenderer] Waiting for globals");
    return null;
  }

  console.log(
    "[PortalIslandsRenderer] Rendering islands:",
    Object.keys(islands)
  );

  return (
    <>
      {Object.entries(islands).map(
        ([id, { Component, props, el, pushEvent }]) => {
          // Clear the element once before first portal render
          if (!clearedElements.current.has(id)) {
            el.innerHTML = "";
            clearedElements.current.add(id);
          }

          return createPortal(
            <IslandRenderer
              key={id}
              Component={Component}
              props={props}
              id={id}
              pushEvent={pushEvent}
            />,
            el
          );
        }
      )}
    </>
  );
};
