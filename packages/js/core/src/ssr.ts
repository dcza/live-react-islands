import React from "react";
import { renderToString, renderToStaticMarkup } from "react-dom/server";
import type { IslandsMap, ContextProviderComponent } from "./types";

/**
 * Server-side rendering function for React islands.
 *
 * This function creates SSR renderers for your island components.
 * It works in any JavaScript runtime: Deno, Node, Bun, etc.
 *
 * @param islands - Map of island components and optional context provider for hydrated roots
 * @param SharedContextProvider - Optional React context provider to wrap all overwrite islands
 * @param onHydrateLiveStore - Optional callback for handling global state during SSR
 */
export function exposeSSR(
  islands: IslandsMap,
  SharedContextProvider: ContextProviderComponent = ({ children }) => children,
  onHydrateLiveStore?: (data: any) => void
) {
  const makeRenderer = (renderFn: typeof renderToString | typeof renderToStaticMarkup) =>
    (IslandComponent: any) =>
    (id: string, props: Record<string, any> = {}, globalState: any = {}) => {
      // Call handler if provided
      if (onHydrateLiveStore) {
        onHydrateLiveStore(globalState);
      }

      return renderFn(
        React.createElement(
          SharedContextProvider,
          null,
          React.createElement(IslandComponent, {
            ...props,
            id,
            pushEvent: () => {},
          })
        )
      );
    };

  // Extract component from islands map config
  const extractComponent = (config: any) => {
    if (typeof config === "function") {
      return config;
    }
    return config.Component;
  };

  // Create renderers for both strategies
  // - renderToString: For hydrate_root (includes React markers for hydration)
  // - renderToStaticMarkup: For overwrite (clean HTML, smaller size)
  const hydrateRenderers = Object.fromEntries(
    Object.entries(islands).map(([key, config]) => [
      key,
      makeRenderer(renderToString)(extractComponent(config)),
    ])
  );

  const overwriteRenderers = Object.fromEntries(
    Object.entries(islands).map(([key, config]) => [
      key,
      makeRenderer(renderToStaticMarkup)(extractComponent(config)),
    ])
  );

  // Main render function that chooses renderer based on strategy
  const renderSSRIsland = (
    key: string,
    id: string,
    props: Record<string, any> = {},
    globalState: any = {},
    strategy: "hydrate_root" | "overwrite" = "overwrite"
  ): string => {
    const renderers = strategy === "hydrate_root" ? hydrateRenderers : overwriteRenderers;
    if (!renderers[key]) {
      throw new Error(`No SSR renderer found for Component "${key}"`);
    }
    return renderers[key](id, props, globalState);
  };

  const getGlobal = () => {
    if (typeof globalThis !== "undefined") return globalThis;
    // @ts-ignore
    if (typeof global !== "undefined") return global;
    if (typeof window !== "undefined") return window;
    return {};
  };

  const universalGlobal = getGlobal();
  //@ts-ignore
  universalGlobal.SSR_MODULE = {
    renderSSRIsland,
    hydrateRenderers,
    overwriteRenderers
  };
}
