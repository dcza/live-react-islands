import React from "react";
import { renderToString, renderToStaticMarkup } from "react-dom/server";
import {
  type IslandsMap,
  type IslandComponent,
  type ContextProviderComponent,
  type LazyIslandFactory,
  NullContextProvider,
} from "./types";

export interface ExposeSSROptions {
  islands: IslandsMap;
  SharedContextProvider?: ContextProviderComponent;
}

const isLazyFactory = (value: unknown): value is LazyIslandFactory => {
  if (typeof value !== "function") return false;
  if ((value as any).prototype?.isReactComponent) return false;
  if ((value as any).Component) return false;
  return value.length === 0;
};

/**
 * Server-side rendering function for React islands.
 *
 * This function creates SSR renderers for your island components.
 * It works in any JavaScript runtime: Deno, Node, Bun, etc.
 *
 * Supports lazy-loaded islands: () => import("./Component")
 */
export async function exposeSSR({
  islands,
  SharedContextProvider = NullContextProvider,
}: ExposeSSROptions) {
  // Resolve all lazy imports first
  const resolvedIslands: Record<string, IslandComponent> = {};

  for (const [name, config] of Object.entries(islands)) {
    if (isLazyFactory(config)) {
      const mod = await config();
      resolvedIslands[name] = mod.default;
    } else if (typeof config === "function") {
      resolvedIslands[name] = config;
    } else {
      resolvedIslands[name] = config.Component;
    }
  }
  const makeRenderer =
    (renderFn: typeof renderToString | typeof renderToStaticMarkup) =>
    (IslandComponent: any) =>
    (
      id: string,
      props: Record<string, any> = {},
      globals: Record<string, any> = {}
    ) => {
      return renderFn(
        React.createElement(
          SharedContextProvider,
          null,
          React.createElement(IslandComponent, {
            ...globals,
            ...props,
            id,
            pushEvent: () => {},
          })
        )
      );
    };

  // Create renderers for both strategies using pre-resolved components
  // - renderToString: For hydrate_root (includes React markers for hydration)
  // - renderToStaticMarkup: For overwrite (clean HTML, smaller size)
  const hydrateRenderers = Object.fromEntries(
    Object.entries(resolvedIslands).map(([key, Component]) => [
      key,
      makeRenderer(renderToString)(Component),
    ])
  );

  const overwriteRenderers = Object.fromEntries(
    Object.entries(resolvedIslands).map(([key, Component]) => [
      key,
      makeRenderer(renderToStaticMarkup)(Component),
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
    const renderers =
      strategy === "hydrate_root" ? hydrateRenderers : overwriteRenderers;
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
    overwriteRenderers,
  };
}
