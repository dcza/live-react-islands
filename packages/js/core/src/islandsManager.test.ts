import React from "react";
import ReactDOM from "react-dom/client";
import IslandsManager, { SHARED_ROOT_ID } from "./islandsManager";
import type {
  SharedIslandsRendererProps,
  IndividualIslandsRendererProps,
  IslandData,
} from "./types";

jest.mock("react-dom/client");

beforeEach(() => {
  jest.spyOn(console, "log").mockImplementation(() => {});
});

afterEach(() => {
  document.body.innerHTML = "";
  jest.restoreAllMocks();
});

describe("IslandsManager.initialize", () => {
  let mockRoot: any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockRoot = { render: jest.fn() };
    (ReactDOM.createRoot as jest.Mock).mockReturnValue(mockRoot);
  });

  test("creates shared root element in DOM", () => {
    IslandsManager.initialize({});

    const rootElement = document.getElementById(SHARED_ROOT_ID);
    expect(rootElement).toBeTruthy();
    expect(rootElement?.style.display).toBe("none");
  });

  test("reuses existing shared root element", () => {
    const existingRoot = document.createElement("div");
    existingRoot.id = SHARED_ROOT_ID;
    document.body.appendChild(existingRoot);

    IslandsManager.initialize({});

    const allRoots = document.querySelectorAll(`#${SHARED_ROOT_ID}`);
    expect(allRoots.length).toBe(1);
    expect(allRoots[0]).toBe(existingRoot);
  });

  test("creates React root with shared root element", () => {
    IslandsManager.initialize({});

    expect(ReactDOM.createRoot).toHaveBeenCalledTimes(1);
    const rootElement = document.getElementById(SHARED_ROOT_ID);
    expect(ReactDOM.createRoot).toHaveBeenCalledWith(rootElement);
  });

  test("storeAccess returns null for non-existent props and globals", () => {
    IslandsManager.initialize({});

    const renderCall = mockRoot.render.mock.calls[0][0];
    const storeAccess = renderCall.props.children.props.children.props.storeAccess;

    expect(storeAccess.getProps("non-existent")).toBeNull();
    expect(storeAccess.getGlobals()).toBeNull();
  });

  test("renders SharedIslandsRenderer with storeAccess", () => {
    IslandsManager.initialize({});

    expect(mockRoot.render).toHaveBeenCalledTimes(1);
    const renderCall = mockRoot.render.mock.calls[0][0];

    expect(renderCall.type).toBeDefined();

    const rendererElement = renderCall.props.children.props.children;
    expect(rendererElement.props.storeAccess).toBeDefined();
    expect(rendererElement.props.storeAccess.subscribeToProps).toBeInstanceOf(Function);
    expect(rendererElement.props.storeAccess.subscribeToGlobals).toBeInstanceOf(Function);
    expect(rendererElement.props.storeAccess.subscribeToSharedIslands).toBeInstanceOf(Function);
    expect(rendererElement.props.storeAccess.getProps).toBeInstanceOf(Function);
    expect(rendererElement.props.storeAccess.getGlobals).toBeInstanceOf(Function);
    expect(rendererElement.props.storeAccess.getSharedIslands).toBeInstanceOf(Function);
  });

  test("uses custom SharedContextProvider when provided", () => {
    const CustomProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => children;
    CustomProvider.displayName = "CustomProvider";

    IslandsManager.initialize({ SharedContextProvider: CustomProvider });

    const renderCall = mockRoot.render.mock.calls[0][0];
    const contextProviderWrapper = renderCall.props.children.type;
    expect(contextProviderWrapper.displayName).toContain("CustomProvider");
  });

  test("uses custom SharedIslandsRenderer when provided", () => {
    const CustomRenderer: React.FC<SharedIslandsRendererProps> = () => null;

    IslandsManager.initialize({ SharedIslandsRenderer: CustomRenderer });

    const renderCall = mockRoot.render.mock.calls[0][0];
    const rendererElement = renderCall.props.children.props.children;
    expect(rendererElement.type).toBe(CustomRenderer);
  });
});

describe("IslandsManager.mountIsland", () => {
  const createMockIslandData = (overrides?: Partial<IslandData>): IslandData => {
    const el = document.createElement("div");
    el.id = "test-island";
    document.body.appendChild(el);

    return {
      id: "test-island",
      el,
      Component: () => null,
      ssrStrategy: "none",
      pushEvent: jest.fn(),
      hydrationData: null,
      globalKeys: [],
      ...overrides,
    };
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("shared islands", () => {
    test("adds island to sharedIslandsStore", () => {
      const mockRoot = { render: jest.fn() };
      (ReactDOM.createRoot as jest.Mock).mockReturnValue(mockRoot);

      const state = IslandsManager.initialize({});
      const renderCall = mockRoot.render.mock.calls[0][0];
      const storeAccess = renderCall.props.children.props.children.props.storeAccess;

      const islandData = createMockIslandData({ ssrStrategy: "none" });
      IslandsManager.mountIsland(state, islandData);

      const sharedIslands = storeAccess.getSharedIslands();
      expect(sharedIslands[islandData.id]).toBe(islandData);
    });

    test("notifies sharedIslands listeners when island is added", () => {
      const mockRoot = { render: jest.fn() };
      (ReactDOM.createRoot as jest.Mock).mockReturnValue(mockRoot);

      const state = IslandsManager.initialize({});
      const renderCall = mockRoot.render.mock.calls[0][0];
      const storeAccess = renderCall.props.children.props.children.props.storeAccess;

      const listener = jest.fn();
      storeAccess.subscribeToSharedIslands(listener);

      const islandData = createMockIslandData({ ssrStrategy: "none" });
      IslandsManager.mountIsland(state, islandData);

      expect(listener).toHaveBeenCalledTimes(1);
    });

    test("handles both 'none' and 'overwrite' strategies via shared store", () => {
      const mockRoot = { render: jest.fn() };
      (ReactDOM.createRoot as jest.Mock).mockReturnValue(mockRoot);

      const state = IslandsManager.initialize({});
      const renderCall = mockRoot.render.mock.calls[0][0];
      const storeAccess = renderCall.props.children.props.children.props.storeAccess;

      const noneIsland = createMockIslandData({ id: "none-island", ssrStrategy: "none" });
      const overwriteIsland = createMockIslandData({ id: "overwrite-island", ssrStrategy: "overwrite" });

      IslandsManager.mountIsland(state, noneIsland);
      IslandsManager.mountIsland(state, overwriteIsland);

      const sharedIslands = storeAccess.getSharedIslands();
      expect(sharedIslands["none-island"]).toBe(noneIsland);
      expect(sharedIslands["overwrite-island"]).toBe(overwriteIsland);
    });
  });

  describe("individual islands (hydrate_root)", () => {
    test("calls ReactDOM.hydrateRoot for 'hydrate_root' strategy", () => {
      const mockRoot = { render: jest.fn() };
      const mockHydrateRoot = { unmount: jest.fn() };
      (ReactDOM.createRoot as jest.Mock).mockReturnValue(mockRoot);
      (ReactDOM.hydrateRoot as jest.Mock).mockReturnValue(mockHydrateRoot);

      const state = IslandsManager.initialize({});
      const islandData = createMockIslandData({
        ssrStrategy: "hydrate_root",
        hydrationData: { props: {}, globals: {} },
      });

      IslandsManager.mountIsland(state, islandData);

      expect(ReactDOM.hydrateRoot).toHaveBeenCalledWith(
        islandData.el,
        expect.anything()
      );
    });

    test("passes island data and storeAccess to renderer", () => {
      const mockRoot = { render: jest.fn() };
      const mockHydrateRoot = { unmount: jest.fn() };
      (ReactDOM.createRoot as jest.Mock).mockReturnValue(mockRoot);
      (ReactDOM.hydrateRoot as jest.Mock).mockReturnValue(mockHydrateRoot);

      const state = IslandsManager.initialize({});
      const islandData = createMockIslandData({
        ssrStrategy: "hydrate_root",
        hydrationData: { props: { foo: "bar" }, globals: { user: "test" } },
      });

      IslandsManager.mountIsland(state, islandData);

      const hydrateCall = (ReactDOM.hydrateRoot as jest.Mock).mock.calls[0];
      expect(hydrateCall[0]).toBe(islandData.el);

      const rendererElement = hydrateCall[1].props.children;
      expect(rendererElement.props.data).toBe(islandData);
      expect(rendererElement.props.storeAccess).toBeDefined();
      expect(rendererElement.props.storeAccess.getProps).toBeInstanceOf(Function);
      expect(rendererElement.props.storeAccess.getGlobals).toBeInstanceOf(Function);
    });

    test("uses custom IndividualIslandRenderer when provided", () => {
      const mockRoot = { render: jest.fn() };
      const mockHydrateRoot = { unmount: jest.fn() };
      (ReactDOM.createRoot as jest.Mock).mockReturnValue(mockRoot);
      (ReactDOM.hydrateRoot as jest.Mock).mockReturnValue(mockHydrateRoot);

      const CustomIndividualRenderer: React.FC<IndividualIslandsRendererProps> = () => null;

      const state = IslandsManager.initialize({});
      const islandData = createMockIslandData({
        ssrStrategy: "hydrate_root",
        hydrationData: { props: {}, globals: {} },
      });

      IslandsManager.mountIsland(state, islandData, CustomIndividualRenderer);

      const hydrateCall = (ReactDOM.hydrateRoot as jest.Mock).mock.calls[0];
      const rendererElement = hydrateCall[1].props.children;
      const wrappedRenderer = rendererElement.type;
      expect(wrappedRenderer.displayName).toContain("HydratedRoot");
    });
  });
});

describe("IslandsManager.updateIslandProps", () => {
  let state: any;
  let storeAccess: any;

  beforeEach(() => {
    jest.clearAllMocks();
    const mockRoot = { render: jest.fn() };
    (ReactDOM.createRoot as jest.Mock).mockReturnValue(mockRoot);

    state = IslandsManager.initialize({});
    const renderCall = mockRoot.render.mock.calls[0][0];
    storeAccess = renderCall.props.children.props.children.props.storeAccess;
  });

  test("makes props available via storeAccess.getProps", () => {
    const props = { foo: "bar", count: 42 };
    IslandsManager.updateIslandProps(state, "island-1", props);

    expect(storeAccess.getProps("island-1")).toEqual(props);
  });

  test("notifies subscribers with new props", () => {
    const listener = jest.fn();
    let capturedProps;

    storeAccess.subscribeToProps(() => {
      listener();
      capturedProps = storeAccess.getProps("island-1");
    });

    const newProps = { foo: "bar" };
    IslandsManager.updateIslandProps(state, "island-1", newProps);

    expect(listener).toHaveBeenCalledTimes(1);
    expect(capturedProps).toEqual(newProps);
  });

  test("overwrites previous props for same island", () => {
    IslandsManager.updateIslandProps(state, "island-1", { foo: "bar" });
    IslandsManager.updateIslandProps(state, "island-1", { foo: "baz" });

    expect(storeAccess.getProps("island-1")).toEqual({ foo: "baz" });
  });
});

describe("IslandsManager.updateGlobals", () => {
  let state: any;
  let storeAccess: any;

  beforeEach(() => {
    jest.clearAllMocks();
    const mockRoot = { render: jest.fn() };
    (ReactDOM.createRoot as jest.Mock).mockReturnValue(mockRoot);

    state = IslandsManager.initialize({});
    const renderCall = mockRoot.render.mock.calls[0][0];
    storeAccess = renderCall.props.children.props.children.props.storeAccess;
  });

  test("makes globals available via storeAccess.getGlobals", () => {
    const globals = { user: "test", theme: "dark", __version: 0 };
    IslandsManager.updateGlobals(state, globals);

    expect(storeAccess.getGlobals()).toEqual(globals);
  });

  test("notifies subscribers with new globals", () => {
    const listener = jest.fn();
    let capturedGlobals;

    storeAccess.subscribeToGlobals(() => {
      listener();
      capturedGlobals = storeAccess.getGlobals();
    });

    const newGlobals = { user: "test", __version: 0 };
    IslandsManager.updateGlobals(state, newGlobals);

    expect(listener).toHaveBeenCalledTimes(1);
    expect(capturedGlobals).toEqual(newGlobals);
  });

  test("storeAccess continues to see updates after multiple changes", () => {
    const globals1 = { user: "test1", __version: 0 };
    const globals2 = { user: "test2", __version: 1 };

    IslandsManager.updateGlobals(state, globals1);
    expect(storeAccess.getGlobals()).toEqual(globals1);

    IslandsManager.updateGlobals(state, globals2);
    expect(storeAccess.getGlobals()).toEqual({ ...globals1, ...globals2 });
  });
});

describe("IslandsManager.resetGlobals", () => {
  let state: any;
  let storeAccess: any;

  beforeEach(() => {
    jest.clearAllMocks();
    const mockRoot = { render: jest.fn() };
    (ReactDOM.createRoot as jest.Mock).mockReturnValue(mockRoot);

    state = IslandsManager.initialize({});
    const renderCall = mockRoot.render.mock.calls[0][0];
    storeAccess = renderCall.props.children.props.children.props.storeAccess;
  });

  test("clears globals via storeAccess.getGlobals", () => {
    const globals = { user: "test", theme: "dark", __version: 5 };
    IslandsManager.updateGlobals(state, globals);
    expect(storeAccess.getGlobals()).toEqual(globals);

    IslandsManager.resetGlobals(state);
    expect(storeAccess.getGlobals()).toBeNull();
  });

  test("allows new globals with lower version after reset", () => {
    const globals1 = { user: "test1", __version: 5 };
    IslandsManager.updateGlobals(state, globals1);

    IslandsManager.resetGlobals(state);

    const globals2 = { user: "test2", __version: 0 };
    IslandsManager.updateGlobals(state, globals2);
    expect(storeAccess.getGlobals()).toEqual(globals2);
  });
});

describe("IslandsManager.unmountIsland", () => {
  const createMockIslandData = (overrides?: Partial<IslandData>): IslandData => {
    const el = document.createElement("div");
    el.id = overrides?.id || "test-island";
    document.body.appendChild(el);

    return {
      id: overrides?.id || "test-island",
      el,
      Component: () => null,
      ssrStrategy: "none",
      pushEvent: jest.fn(),
      hydrationData: null,
      globalKeys: [],
      ...overrides,
    };
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("props no longer accessible via storeAccess.getProps", () => {
    const mockRoot = { render: jest.fn() };
    (ReactDOM.createRoot as jest.Mock).mockReturnValue(mockRoot);

    const state = IslandsManager.initialize({});
    const renderCall = mockRoot.render.mock.calls[0][0];
    const storeAccess = renderCall.props.children.props.children.props.storeAccess;

    IslandsManager.updateIslandProps(state, "island-1", { foo: "bar" });
    expect(storeAccess.getProps("island-1")).toEqual({ foo: "bar" });

    IslandsManager.unmountIsland(state, "island-1");
    expect(storeAccess.getProps("island-1")).toBeNull();
  });

  test("removes island from sharedIslandsStore for shared islands", () => {
    const mockRoot = { render: jest.fn() };
    (ReactDOM.createRoot as jest.Mock).mockReturnValue(mockRoot);

    const state = IslandsManager.initialize({});
    const renderCall = mockRoot.render.mock.calls[0][0];
    const storeAccess = renderCall.props.children.props.children.props.storeAccess;

    const islandData = createMockIslandData({ id: "island-1", ssrStrategy: "none" });
    IslandsManager.mountIsland(state, islandData);

    expect(storeAccess.getSharedIslands()["island-1"]).toBe(islandData);

    IslandsManager.unmountIsland(state, "island-1");

    expect(storeAccess.getSharedIslands()["island-1"]).toBeUndefined();
  });

  test("calls unmount on React root for individual islands", () => {
    const mockRoot = { render: jest.fn() };
    const mockHydrateRoot = { unmount: jest.fn() };
    (ReactDOM.createRoot as jest.Mock).mockReturnValue(mockRoot);
    (ReactDOM.hydrateRoot as jest.Mock).mockReturnValue(mockHydrateRoot);

    const state = IslandsManager.initialize({});
    const islandData = createMockIslandData({
      id: "hydrate-island",
      ssrStrategy: "hydrate_root",
      hydrationData: { props: {}, globals: {} },
    });

    const mountedState = IslandsManager.mountIsland(state, islandData);
    IslandsManager.unmountIsland(mountedState, "hydrate-island");

    expect(mockHydrateRoot.unmount).toHaveBeenCalledTimes(1);
  });
});
