import React, { useRef, memo, useSyncExternalStore, useMemo } from "react";
import { createPortal } from "react-dom";
import type {
  IslandData,
  SharedIslandsRendererProps,
  IslandStoreAccess,
} from "./types";
import { IslandContextProvider } from "./context";

const PortalIsland = memo(
  ({
    data,
    storeAccess,
  }: {
    data: IslandData;
    storeAccess: IslandStoreAccess;
  }) => {
    const {
      Component,
      ContextProvider,
      id,
      pushEvent,
      ssrStrategy,
      el,
      globalKeys,
    } = data;

    const MemoizedComponent = useMemo(() => memo(Component), [Component]);
    const MemoizedContextProvider = useMemo(
      () => (ContextProvider ? memo(ContextProvider) : null),
      [ContextProvider]
    );

    const currentProps = useSyncExternalStore(
      storeAccess.subscribeToProps,
      () => storeAccess.getProps(id),
      () => null
    );

    const allGlobals = useSyncExternalStore(
      storeAccess.subscribeToGlobals,
      storeAccess.getGlobals,
      () => null
    );

    const didClearRef = useRef(false);
    if (ssrStrategy === "overwrite" && !didClearRef.current) {
      el.innerHTML = "";
      didClearRef.current = true;
    }

    if (!allGlobals) {
      console.log("[PortalIsland] Waiting for globals", id);
      return null;
    }

    console.log("[PortalIsland] Rendering", { id, allGlobals });

    const relevantGlobals: Record<string, any> = {};
    if (allGlobals) {
      globalKeys.forEach((key) => {
        if (key in allGlobals) {
          relevantGlobals[key] = allGlobals[key];
        }
      });
    }

    const mergedProps = { ...relevantGlobals, ...currentProps };

    const contextValue = useMemo(() => ({ id, storeAccess }), [id, storeAccess]);

    const islandNode = (
      <MemoizedComponent {...mergedProps} id={id} pushEvent={pushEvent} />
    );

    const withContext = (
      <IslandContextProvider.Provider value={contextValue}>
        {islandNode}
      </IslandContextProvider.Provider>
    );

    const content = MemoizedContextProvider ? (
      <MemoizedContextProvider>{withContext}</MemoizedContextProvider>
    ) : (
      withContext
    );

    return createPortal(content, el);
  }
);
PortalIsland.displayName = "[ReactLiveIslands]PortalIsland";

export const PortalIslandsRenderer: React.FC<SharedIslandsRendererProps> = ({
  storeAccess,
}) => {
  const sharedIslandsObj = useSyncExternalStore(
    storeAccess.subscribeToSharedIslands,
    storeAccess.getSharedIslands
  );

  const islands = Object.values(sharedIslandsObj);

  console.log(
    "[PortalIslandsRenderer] Rendering islands:",
    islands.map((d) => d.id)
  );

  return (
    <>
      {islands.map((data) => (
        <PortalIsland key={data.id} data={data} storeAccess={storeAccess} />
      ))}
    </>
  );
};
PortalIslandsRenderer.displayName = "[ReactLiveIslands]PortalIslandsRenderer";
