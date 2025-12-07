import React, { useState, useLayoutEffect, useRef, memo } from "react";
import ReactDOM from "react-dom/client";
import { createPortal } from "react-dom";
// import { exposeSSR } from "./renderersSSR";

const IslandsRoot = ({ rootId, globalsReady: initialGlobalsReady }) => {
  const [globalsReady, setGlobalsReady] = useState(initialGlobalsReady);
  const [islands, setIslands] = useState({});
  const clearedElements = useRef(new Set());
  const memoizedComponents = useRef(new Map());

  window.__ReactIslands[rootId].setGlobalsReady = (r) => setGlobalsReady(r);

  window.__ReactIslands[rootId].addIsland = ({
    id,
    Component,
    props,
    el,
    pushEvent,
  }) => {
    console.log("Adding Island: ", {
      id,
      Component,
      props,
      el,
      pushEvent,
    });

    setIslands((prev) => ({
      ...prev,
      [id]: { Component, props, el, pushEvent },
    }));
  };

  window.__ReactIslands[rootId].updateIsland = ({ id, props }) => {
    setIslands((prev) => ({
      ...prev,
      [id]: { ...prev[id], props: { ...prev[id]?.props, ...props } },
    }));
  };

  window.__ReactIslands[rootId].removeIsland = (id) => {
    setIslands((prev) => {
      const newState = { ...prev };
      delete newState[id];

      return newState;
    });
  };

  if (!globalsReady) {
    console.log("Not rendering root: Waiting for globals ", islands);
    return null;
  }

  console.log("Rerendering root: ", islands);

  return (
    <>
      {Object.entries(islands).map(
        ([id, { Component, props, el, pushEvent }]) => {
          // Clear the element once before first portal render
          if (!clearedElements.current.has(id)) {
            el.innerHTML = "";
            clearedElements.current.add(id);
          }

          // Memoize each component instance to prevent unnecessary re-renders
          if (!memoizedComponents.current.has(Component)) {
            memoizedComponents.current.set(Component, memo(Component));
          }
          const MemoizedComponent = memoizedComponents.current.get(Component);

          return createPortal(
            <MemoizedComponent key={id} {...props} {...{ id, pushEvent }} />,
            el
          );
        }
      )}
    </>
  );
};

function handlePushEvent(eventName, payload) {
  this.pushEventTo(`#${this.el.id}`, eventName, payload);
}

const DefaultContextProvider = ({ children }) => children;

export function createHooks({
  islands: islandComponents = {},
  ContextProvider = DefaultContextProvider,
  globalStoreHandler = null,
  rootId = "react-islands-root",
}) {
  let globalsRequested = false;

  function initializeReactRoot() {
    if (!window.__ReactIslandRoots[rootId]) {
      // Always ensure islands registry exists when creating new root
      window.__ReactIslands[rootId] = { globalsReady: !globalStoreHandler };

      let rootElement = document.getElementById(rootId);
      if (!rootElement) {
        rootElement = document.createElement("div");
        rootElement.id = rootId;
        rootElement.style.display = "none";
        document.body.appendChild(rootElement);
      }
      const root = ReactDOM.createRoot(rootElement);
      root.render(
        <ContextProvider>
          <IslandsRoot rootId={rootId} globalsReady={!globalStoreHandler} />
        </ContextProvider>
      );
      window.__ReactIslandRoots[rootId] = root;
    }
  }

  // // Test for running in server environment
  // if (typeof document === "undefined") {
  //   exposeSSR(islandComponents, ContextProvider, globalStoreHandler);
  //   return;
  // }

  if (!window.__ReactIslandRoots) {
    window.__ReactIslandRoots = {};
    window.__ReactIslands = {};
  }

  if (document.readyState === "loading")
    document.addEventListener("DOMContentLoaded", initializeReactRoot);
  else initializeReactRoot();

  // Track navigation and clean up on page change
  let navigationCounter = 0;
  window.addEventListener("phx:page-loading-start", () => {
    navigationCounter++;
  });

  const Hook = {
    mounted() {
      console.log("[ReactIsland] Hook mounted callback");
      // Detect if navigation occurred since last mount
      if (
        window.__lastNavigationCounter !== undefined &&
        window.__lastNavigationCounter !== navigationCounter
      ) {
        console.log("[ReactIsland] Navigation detected, cleaning up old root");
        if (window.__ReactIslandRoots[rootId]) {
          window.__ReactIslandRoots[rootId].unmount();
          delete window.__ReactIslandRoots[rootId];
          delete window.__ReactIslands[rootId];
        }
        globalsRequested = false;
      }

      window.__lastNavigationCounter = navigationCounter;

      // Initialize root if needed
      initializeReactRoot();

      if (!globalsRequested && globalStoreHandler) {
        globalsRequested = true;
        this.pushEvent("get_globals", {}, (reply, ref) => {
          globalStoreHandler(reply);

          this.handleEvent("update_globals", (data) => {
            globalStoreHandler(data);
          });

          window.__ReactIslands[rootId].setGlobalsReady(true);
        });
      }

      console.log("[ReactIsland] Mounting", {
        el: this.el,
        dataset: { ...this.el.dataset },
      });
      const { component: componentName } = this.el.dataset;

      const IslandComponent = islandComponents[componentName];

      if (!IslandComponent) {
        console.error(`[ReactIsland] Component '${componentName}' not found`);
        this.el.innerHTML = `<div style="color: red; padding: 10px; border: 1px solid red;">
        Error: Island component '${componentName}' not found
      </div>`;
        return;
      }

      if (!window.__ReactIslands[rootId]) {
        console.error(`[ReactIsland] Root '${rootId}' not initialized`);
        this.el.innerHTML = `<div style="color: red; padding: 10px; border: 1px solid red;">
        Error: React Islands root '${rootId}' not initialized
      </div>`;
        return;
      }

      // Wait for React root to finish rendering and assign methods
      const addIslandWhenReady = () => {
        if (typeof window.__ReactIslands[rootId].addIsland === "function") {
          window.__ReactIslands[rootId].addIsland({
            id: this.el.id,
            Component: IslandComponent,
            props: {},
            el: this.el,
            pushEvent: handlePushEvent.bind(this),
          });
        } else {
          console.log("[ReactIsland] Waiting for root to be ready...");
          setTimeout(addIslandWhenReady, 10);
        }
      };

      addIslandWhenReady();

      this.handleEvent("p", ({ id, ...props }) => {
        if (id !== this.el.id) return;
        window.__ReactIslands[rootId].updateIsland({
          id: this.el.id,
          props,
        });
      });
    },

    updated() {
      console.log("[ReactIsland] Hook updated callback");
    },

    destroyed() {
      console.log("[ReactIsland] Hook destroyed callback");
      window.__ReactIslands[rootId].removeIsland(this.el.id);
    },
  };

  return { LiveReactIslands: Hook };
}
