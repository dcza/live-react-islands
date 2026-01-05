import React, { useSyncExternalStore, memo, useMemo } from "react";
import type { IndividualIslandsRendererProps } from "./types";
import { IslandContextProvider } from "./context";

export const IndividualIslandRenderer: React.FC<
  IndividualIslandsRendererProps
> = ({ data, storeAccess }) => {
  const { Component, ContextProvider, id, pushEvent, globalKeys } = data;

  const MemoizedComponent = useMemo(() => memo(Component), [Component]);
  const MemoizedContextProvider = useMemo(
    () => (ContextProvider ? memo(ContextProvider) : null),
    [ContextProvider]
  );

  const currentProps = useSyncExternalStore(
    storeAccess.subscribeToProps,
    () => storeAccess.getProps(id),
    () => data.hydrationData?.props
  );

  // Check once if hydration globals version matches store version
  const serverGlobalsSnapshot = useMemo(() => {
    const hydrationGlobals = data.hydrationData?.globals;
    if (!hydrationGlobals) return () => hydrationGlobals;
    let comparedVersions = false;
    let useStoreReference = false;
    return () => {
      if (!comparedVersions) {
        comparedVersions = true;
        const storeGlobals = storeAccess.getGlobals();
        const hydrationVersion = hydrationGlobals.__version ?? -1;
        const storeVersion = storeGlobals?.__version ?? -1;
        useStoreReference = storeVersion === hydrationVersion;
      }
      return useStoreReference ? storeAccess.getGlobals() : hydrationGlobals;
    };
  }, [data.hydrationData?.globals, storeAccess]);

  const globals = useSyncExternalStore(
    storeAccess.subscribeToGlobals,
    storeAccess.getGlobals,
    serverGlobalsSnapshot
  );

  const filteredGlobals: Record<string, any> = {};
  if (globals) {
    globalKeys.forEach((key) => {
      if (key in globals) {
        filteredGlobals[key] = globals[key];
      }
    });
  }

  const contextValue = useMemo(() => ({ id, storeAccess }), [id, storeAccess]);

  const islandNode = (
    <MemoizedComponent
      {...filteredGlobals}
      {...currentProps}
      id={id}
      pushEvent={pushEvent}
    />
  );

  const withContext = (
    <IslandContextProvider.Provider value={contextValue}>
      {islandNode}
    </IslandContextProvider.Provider>
  );

  return MemoizedContextProvider ? (
    <MemoizedContextProvider>{withContext}</MemoizedContextProvider>
  ) : (
    withContext
  );
};

IndividualIslandRenderer.displayName =
  "[ReactLiveIslands] IndividualIslandRenderer";
