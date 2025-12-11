import IslandsManager, { Manager } from "./islandsManager";
import type {
  IslandsMap,
  SSRStrategy,
  PushEventFn,
  ContextProviderComponent,
  IslandComponent,
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
  globalStoreHandler?: ((data: any) => void) | null;
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

const NullContextProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => children;

const extractIslandConfig = (
  islandsMap: IslandsMap,
  componentName: string,
  defaultContextProvider: ContextProviderComponent
): {
  Component: IslandComponent;
  ContextProvider: ContextProviderComponent;
} | null => {
  const config = islandsMap[componentName];

  if (!config) {
    return null;
  }

  // Handle both direct component and config object
  if (typeof config === "function") {
    return { Component: config, ContextProvider: defaultContextProvider };
  }

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
  globalStoreHandler = null,
  manager = IslandsManager,
}: CreateHooksOptions) {
  console.log(`[LiveReactIslands] Creating hooks`);
  let managerState = manager.initialize({ SharedContextProvider });

  let globalsRequested = false;

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
      if (!globalStoreHandler) {
        managerState = manager.enableRendering(managerState);
      } else if (!globalsRequested) {
        globalsRequested = true;
        this.pushEvent("get_globals", {}, (reply, ref) => {
          globalStoreHandler(reply);
          this.handleEvent("update_globals", (data) => {
            globalStoreHandler(data);
          });
          managerState = manager.enableRendering(managerState);
        });
      }

      // Handle mount logic
      const { comp: componentName, ssr: ssrData } = this.el.dataset;
      if (!componentName) {
        console.error(
          `[LiveReactIslands] Element '${this.el.id}' missing data-comp attribute`
        );
        return;
      }

      const islandConfig = extractIslandConfig(
        islandsMap,
        componentName,
        SharedContextProvider
      );
      if (!islandConfig) {
        console.error(
          `[LiveReactIslands] React island '${componentName}' not found`
        );
        return;
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

      managerState = manager.mountIsland(managerState, {
        id: this.el.id,
        el: this.el,
        Component: islandConfig.Component,
        ContextProvider: islandConfig.ContextProvider,
        ssrStrategy,
        pushEvent,
        props: {},
      });

      // Setup prop update handler
      this.handleEvent(
        "p",
        ({ id, ...props }: { id: string; [key: string]: any }) => {
          if (id !== this.el.id) return;
          manager.updateIslandProps(managerState, this.el.id, props);
        }
      );
    },

    updated(this: LiveViewHook) {
      console.log("[Hook] Updated:", this.el.id);
    },

    destroyed(this: LiveViewHook) {
      console.log("[Hook] Destroyed:", this.el.id);

      managerState = manager.unmountIsland(managerState, this.el.id);
    },
  };

  return { LiveReactIslands: Hook };
}
