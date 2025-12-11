import React, {
  useState,
  useRef,
  useImperativeHandle,
  forwardRef,
  memo,
  ComponentType,
  useEffect,
} from "react";
import { createPortal } from "react-dom";
import type { IslandData, IslandComponent } from "./types";

interface PortalIslandsRendererProps {
  onReady?: () => void;
}

export interface PortalIslandsRendererHandle {
  setRenderingEnabled: (enabled: boolean) => void;
  addIsland: (data: IslandData) => void;
  updateIsland: (id: string, props: Record<string, any>) => void;
  removeIsland: (id: string) => void;
}

export const PortalIslandsRenderer = forwardRef<
  PortalIslandsRendererHandle,
  PortalIslandsRendererProps
>((props, ref) => {
  const [renderingEnabled, setRenderingEnabled] = useState(false);
  const [islands, setIslands] = useState<Record<string, IslandData>>({});
  const clearedElements = useRef(new Set<string>());
  const memoizedComponents = useRef(
    new Map<IslandComponent, ComponentType<any>>()
  );

  useEffect(() => {
    props.onReady?.();
  }, []);

  // Expose methods via ref
  useImperativeHandle(ref, () => ({
    setRenderingEnabled,
    addIsland: (data: IslandData) => {
      console.log("[PortalIslandsRenderer] Adding island:", data.el.id);
      setIslands((prev) => ({
        ...prev,
        [data.el.id]: data,
      }));
    },
    updateIsland: (id, props) => {
      setIslands((prev) => ({
        ...prev,
        [id]: { ...prev[id], props: { ...prev[id]?.props, ...props } },
      }));
    },
    removeIsland: (id: string) => {
      clearedElements.current?.delete(id);
      setIslands((prev) => {
        const newState = { ...prev };
        delete newState[id];
        return newState;
      });
    },
  }));

  if (!renderingEnabled) {
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
        ([id, { Component, props, el, pushEvent, ssrStrategy }]) => {
          // Clear element ssr content once before first render
          if (ssrStrategy === "overwrite" && !clearedElements.current.has(id)) {
            el.innerHTML = "";
            clearedElements.current.add(id);
          }

          // Memoize component to prevent unnecessary re-renders
          if (!memoizedComponents.current.has(Component)) {
            memoizedComponents.current.set(Component, memo(Component));
          }
          const MemoizedComponent = memoizedComponents.current.get(Component)!;

          return createPortal(
            <MemoizedComponent
              key={id}
              {...props}
              id={id}
              pushEvent={pushEvent}
            />,
            el
          );
        }
      )}
    </>
  );
});
