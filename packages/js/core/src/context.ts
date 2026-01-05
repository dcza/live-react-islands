import { createContext } from "react";
import type { IslandStoreAccess } from "./types";

export interface IslandContext {
  id: string;
  storeAccess: IslandStoreAccess;
}

export const IslandContextProvider = createContext<IslandContext | null>(null);
