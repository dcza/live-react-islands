import { useContext, useSyncExternalStore, useMemo } from "react";
import type { StreamHandle } from "./types";
import { IslandContextProvider } from "./context";

export interface UseStreamOptions<T> {
  limit?: number;
  capper?: (items: T[]) => T[];
}

export function useStream<T extends { id: string | number }>(
  handle: StreamHandle,
  options?: UseStreamOptions<T>
): T[] {
  const context = useContext(IslandContextProvider);
  if (!context) {
    throw new Error("useStream must be used within an Island component");
  }

  const { id: islandId, storeAccess } = context;

  const subscribe = useMemo(
    () => (cb: () => void) =>
      storeAccess.subscribeToStream(islandId, handle.name, cb, {
        limit: options?.limit,
        capper: options?.capper as ((items: any[]) => any[]) | undefined,
      }),
    [storeAccess, islandId, handle.name, options?.limit, options?.capper]
  );

  const getSnapshot = useMemo(
    () => () => storeAccess.getStreamItems(islandId, handle.name) as T[],
    [storeAccess, islandId, handle.name]
  );

  return useSyncExternalStore(subscribe, getSnapshot, () => handle.initial as T[]);
}
