import IslandsManager, { Manager } from "./islandsManager";
import {
  type IslandsMap,
  type SSRStrategy,
  type PushEventFn,
  type ContextProviderComponent,
  type IslandComponent,
  type LazyIslandFactory,
  type StreamHandle,
  NullContextProvider,
  StreamAction,
} from "./types";

// ============================================================================
// Types
// ============================================================================

interface LiveViewHook {
  el: HTMLElement;
  pushEvent: (
    event: string,
    payload: any,
    callback?: (reply: any, ref: any) => void
  ) => void;
  pushEventTo: (target: string, event: string, payload: any) => void;
  handleEvent: (event: string, callback: (data: any) => void) => void;
}

export interface CreateHooksOptions {
  islands: IslandsMap;
  SharedContextProvider?: ContextProviderComponent;
  manager?: Manager;
}

// ============================================================================
// Event Handler Adapter
// ============================================================================

function createPushEventFn(hook: LiveViewHook): PushEventFn {
  return (eventName: string, payload: any) => {
    hook.pushEventTo(`#${hook.el.id}`, eventName, payload);
  };
}

// ============================================================================
// Helper
// ============================================================================

const resolvedComponentsCache = new Map<string, IslandComponent>();

const isLazyFactory = (value: unknown): value is LazyIslandFactory => {
  if (typeof value !== "function") return false;
  // Check if it's a React component (has prototype.isReactComponent for class components)
  if ((value as any).prototype?.isReactComponent) return false;
  // Check if it's a config object getter (would have Component property)
  if ((value as any).Component) return false;
  // Assume zero-arg functions that aren't class components are lazy factories
  return value.length === 0;
};

const resolveIslandConfig = async (
  islandsMap: IslandsMap,
  componentName: string,
  defaultContextProvider: ContextProviderComponent
): Promise<{
  Component: IslandComponent;
  ContextProvider: ContextProviderComponent;
} | null> => {
  const config = islandsMap[componentName];

  if (!config) {
    return null;
  }

  // Check cache first for lazy-loaded components
  const cached = resolvedComponentsCache.get(componentName);
  if (cached) {
    return { Component: cached, ContextProvider: defaultContextProvider };
  }

  // Handle lazy factory: () => import("./Component")
  if (isLazyFactory(config)) {
    const mod = await config();
    const Component = mod.default;
    resolvedComponentsCache.set(componentName, Component);
    return { Component, ContextProvider: defaultContextProvider };
  }

  // Handle direct component
  if (typeof config === "function") {
    return { Component: config, ContextProvider: defaultContextProvider };
  }

  // Handle config object
  return {
    Component: config.Component,
    ContextProvider: config.ContextProvider || defaultContextProvider,
  };
};

// ============================================================================
// Main Hook Factory (LiveView Adapter Layer)
// ============================================================================

export function createHooks({
  islands: islandsMap = {},
  SharedContextProvider = NullContextProvider,
  manager = IslandsManager,
}: CreateHooksOptions) {
  console.log(`[LiveReactIslands] Creating hooks`);
  let managerState = manager.initialize({ SharedContextProvider });

  let globalsRequested = false;
  const pendingMounts = new Set<string>();

  const Hook: Partial<LiveViewHook> & {
    mounted: (this: LiveViewHook) => void;
    updated?: (this: LiveViewHook) => void;
    destroyed: (this: LiveViewHook) => void;
  } = {
    mounted(this: LiveViewHook) {
      console.log("[Hook] Mount:", this.el.id);
      if (!this.el.id) {
        console.error(`[LiveReactIslands] Island element missing unique id`);
        return;
      }

      // Pull globals once on first island mount
      if (!globalsRequested) {
        globalsRequested = true;
        this.handleEvent("lri-g", (data) => {
          managerState = manager.updateGlobals(managerState, data);
        });
        this.pushEvent("lri-g", {}, (reply) => {
          managerState = manager.updateGlobals(managerState, reply);
        });
      }

      const {
        comp: componentName,
        ssr: ssrData,
        props: propsData,
        schema: schemaData,
        globals: globalsData,
        globalsVersion: globalsVersionData,
      } = this.el.dataset;
      if (!componentName) {
        console.error(
          `[LiveReactIslands] Element '${this.el.id}' missing data-comp attribute`
        );
        return;
      }

      let schema: { p: string[]; g: string[]; i: number } = {
        p: [],
        g: [],
        i: 0,
      };
      if (schemaData) {
        try {
          schema = JSON.parse(schemaData);
        } catch (e) {
          console.error(
            `[Island(${this.el.id})] Failed to parse data-schema:`,
            e
          );
        }
      }

      let initialProps: Record<string, any> = {};
      if (propsData) {
        try {
          const propsArray = JSON.parse(propsData);
          schema.p.forEach((propName, idx) => {
            const value = propsArray[idx];
            if (value?.__s !== undefined) {
              const streamName = schema.p[value.__s];
              managerState = manager.initializeStream(
                managerState,
                this.el.id,
                streamName,
                value.i
              );
              const handle: StreamHandle = {
                name: streamName,
                initial: value.i,
              };
              initialProps[propName] = handle;
            } else {
              initialProps[propName] = value;
            }
          });
        } catch (e) {
          console.error(
            `[Island(${this.el.id})] Failed to parse data-props:`,
            e
          );
        }
      }

      // Only for hydrate_root strategy
      let initialGlobals: Record<string, any> = {};
      if (globalsData) {
        try {
          const globalsArray = JSON.parse(globalsData);
          schema.g.forEach((globalName, idx) => {
            initialGlobals[globalName] = globalsArray[idx];
          });
          if (!globalsVersionData)
            throw "Missing data-globals-version attribute";
          initialGlobals.__version = parseInt(globalsVersionData, 10);
        } catch (e) {
          console.error(
            `[Island(${this.el.id})] Failed to parse data-globals:`,
            e
          );
        }
      }

      let ssrStrategy: SSRStrategy;
      switch (ssrData) {
        case "overwrite":
          ssrStrategy = "overwrite";
          break;
        case "hydrate_root":
          ssrStrategy = "hydrate_root";
          break;
        default:
          ssrStrategy = "none";
      }

      const pushEvent = createPushEventFn(this);
      const elId = this.el.id;
      const el = this.el;

      pendingMounts.add(elId);

      (async () => {
        const islandConfig = await resolveIslandConfig(
          islandsMap,
          componentName,
          SharedContextProvider
        );

        if (!pendingMounts.has(elId)) return;
        pendingMounts.delete(elId);

        if (!islandConfig) {
          console.error(
            `[LiveReactIslands] React island '${componentName}' not found`
          );
          return;
        }

        managerState = manager.updateIslandProps(
          managerState,
          elId,
          initialProps
        );

        managerState = manager.mountIsland(managerState, {
          id: elId,
          el,
          Component: islandConfig.Component,
          ContextProvider: islandConfig.ContextProvider,
          ssrStrategy,
          pushEvent,
          hydrationData:
            ssrStrategy === "hydrate_root"
              ? { props: initialProps, globals: initialGlobals }
              : null,
          globalKeys: schema.g,
        });
      })();

      this.handleEvent(
        "lri-p",
        (payload: { i: number; [key: number]: any }) => {
          if (payload.i !== schema.i) return;

          const props: Record<string, any> = {};
          Object.entries(payload).forEach(([key, value]) => {
            if (key === "i") return;
            const idx = parseInt(key, 10);
            if (!isNaN(idx) && schema.p[idx]) {
              props[schema.p[idx]] = value;
            }
          });

          managerState = manager.updateIslandProps(
            managerState,
            this.el.id,
            props
          );
        }
      );

      this.handleEvent(
        "lri-s",
        (payload: { s: number; a: StreamAction; d: any; i: number }) => {
          if (payload.i !== schema.i) return;

          const streamName = schema.p[payload.s];
          if (!streamName) return;

          managerState = manager.updateStream(
            managerState,
            this.el.id,
            streamName,
            payload.a,
            payload.d
          );
        }
      );
    },

    updated(this: LiveViewHook) {
      console.log("[Hook] Updated:", this.el.id);
    },

    destroyed(this: LiveViewHook) {
      console.log("[Hook] Destroyed:", this.el.id);
      pendingMounts.delete(this.el.id);
      managerState = manager.unmountIsland(managerState, this.el.id);
    },
  };

  return { LiveReactIslands: Hook };
}
