import { renderToStaticMarkup } from "react-dom/server";

export function exposeSSR(
  islandComponents,
  ContextProvider,
  onHydrateLiveStore
) {
  const makeRenderSSRIslandStatic =
    (IslandComponent) =>
    (id, props = {}, globalState = {}) => {
      onHydrateLiveStore(globalState);
      return renderToStaticMarkup(
        <div className="opacity-70 pointer-events-none">
          <ContextProvider>
            <IslandComponent {...props} id={id} handleEvent={() => {}} />
          </ContextProvider>
        </div>
      );
    };

  if (globalThis) {
    globalThis.renderSSRIslandStatic = (key, ...args) => {
      if (!globalThis.renderSSRIslandStatic[key])
        throw new Error(`No static renderer found for Component "${key}"`);
      return globalThis.renderSSRIslandStatic[key](...args);
    };
    Object.entries(islandComponents).forEach(([key, IslandComponent]) => {
      if (globalThis.renderSSRIslandStatic[key]) return;
      globalThis.renderSSRIslandStatic[key] =
        makeRenderSSRIslandStatic(IslandComponent);
    });
  }
}
