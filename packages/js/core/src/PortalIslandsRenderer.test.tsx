import React from "react";
import { render, waitFor, act } from "@testing-library/react";
import { PortalIslandsRenderer } from "./PortalIslandsRenderer";
import type {
  IslandData,
  IslandStoreAccess,
} from "./types";

beforeEach(() => {
  jest.spyOn(console, "log").mockImplementation(() => {});
  document.body.innerHTML = "";
});

afterEach(() => {
  jest.restoreAllMocks();
});

describe("PortalIslandsRenderer", () => {
  const createMockStoreAccess = (): {
    storeAccess: IslandStoreAccess;
    setSharedIslands: (islands: Record<string, IslandData>) => void;
    setProps: (islandId: string, props: Record<string, any>) => void;
    setGlobals: (globals: Record<string, any> | null) => void;
  } => {
    const propsMap = new Map<string, Record<string, any>>();
    const propsListeners = new Set<() => void>();
    let globals: Record<string, any> | null = { __version: 1 };
    const globalsListeners = new Set<() => void>();
    let sharedIslands: Record<string, IslandData> = {};
    const sharedIslandsListeners = new Set<() => void>();

    const storeAccess: IslandStoreAccess = {
      getProps: (id: string) => propsMap.get(id) || null,
      subscribeToProps: (cb: () => void) => {
        propsListeners.add(cb);
        return () => propsListeners.delete(cb);
      },
      getGlobals: () => globals,
      subscribeToGlobals: (cb: () => void) => {
        globalsListeners.add(cb);
        return () => globalsListeners.delete(cb);
      },
      getSharedIslands: () => sharedIslands,
      subscribeToSharedIslands: (cb: () => void) => {
        sharedIslandsListeners.add(cb);
        return () => sharedIslandsListeners.delete(cb);
      },
    };

    return {
      storeAccess,
      setSharedIslands: (islands: Record<string, IslandData>) => {
        sharedIslands = islands;
        sharedIslandsListeners.forEach((cb) => cb());
      },
      setProps: (islandId: string, props: Record<string, any>) => {
        propsMap.set(islandId, props);
        propsListeners.forEach((cb) => cb());
      },
      setGlobals: (newGlobals: Record<string, any> | null) => {
        globals = newGlobals;
        globalsListeners.forEach((cb) => cb());
      },
    };
  };

  const createMockIslandData = (
    overrides?: Partial<IslandData>
  ): IslandData => {
    const el = document.createElement("div");
    el.id = overrides?.id || "test-island";
    document.body.appendChild(el);

    return {
      id: overrides?.id || "test-island",
      el,
      Component: ({ count }: { count: number }) => <div>Count: {count}</div>,
      ssrStrategy: "none",
      pushEvent: jest.fn(),
      hydrationData: null,
      globalKeys: [],
      ...overrides,
    };
  };

  test("renders islands from shared islands store", async () => {
    const { storeAccess, setSharedIslands, setProps } = createMockStoreAccess();

    render(<PortalIslandsRenderer storeAccess={storeAccess} />);

    const islandData = createMockIslandData({ id: "island-1" });

    act(() => {
      setProps("island-1", { count: 0 });
      setSharedIslands({ "island-1": islandData });
    });

    await waitFor(() => {
      expect(islandData.el).toHaveTextContent("Count: 0");
    });
  });

  test("removes islands when removed from store", async () => {
    const { storeAccess, setSharedIslands, setProps } = createMockStoreAccess();

    render(<PortalIslandsRenderer storeAccess={storeAccess} />);

    const islandData = createMockIslandData({ id: "island-1" });

    act(() => {
      setProps("island-1", { count: 0 });
      setSharedIslands({ "island-1": islandData });
    });

    await waitFor(() => {
      expect(islandData.el).toHaveTextContent("Count: 0");
    });

    act(() => {
      setSharedIslands({});
    });

    await waitFor(() => {
      expect(islandData.el).toHaveTextContent("");
    });
  });

  test("subscribes to props and globals stores for each island", async () => {
    const { storeAccess, setSharedIslands, setProps } = createMockStoreAccess();

    const subscribeToProps = jest.spyOn(storeAccess, "subscribeToProps");
    const subscribeToGlobals = jest.spyOn(storeAccess, "subscribeToGlobals");

    render(<PortalIslandsRenderer storeAccess={storeAccess} />);

    const islandData = createMockIslandData({ id: "island-1" });

    act(() => {
      setProps("island-1", { count: 0 });
      setSharedIslands({ "island-1": islandData });
    });

    await waitFor(() => {
      expect(subscribeToProps).toHaveBeenCalled();
      expect(subscribeToGlobals).toHaveBeenCalled();
    });
  });

  test("clears innerHTML for overwrite strategy", async () => {
    const { storeAccess, setSharedIslands, setProps } = createMockStoreAccess();

    render(<PortalIslandsRenderer storeAccess={storeAccess} />);

    const el = document.createElement("div");
    el.innerHTML = "<div>SSR content</div>";
    document.body.appendChild(el);

    const islandData: IslandData = {
      id: "island-1",
      el,
      Component: ({ count }: { count: number }) => <div>Count: {count}</div>,
      ssrStrategy: "overwrite",
      pushEvent: jest.fn(),
      hydrationData: null,
      globalKeys: [],
    };

    act(() => {
      setProps("island-1", { count: 0 });
      setSharedIslands({ "island-1": islandData });
    });

    await waitFor(() => {
      expect(el.innerHTML).not.toContain("SSR content");
      expect(el).toHaveTextContent("Count: 0");
    });
  });

  test("merges globals and props for island component", async () => {
    const { storeAccess, setSharedIslands, setProps, setGlobals } = createMockStoreAccess();

    const MockComponent = ({ count, user }: any) => (
      <div>
        {count}-{user}
      </div>
    );

    render(<PortalIslandsRenderer storeAccess={storeAccess} />);

    const islandData = createMockIslandData({
      id: "island-1",
      Component: MockComponent,
      globalKeys: ["user"],
    });

    act(() => {
      setGlobals({ user: "test", __version: 1 });
      setProps("island-1", { count: 5 });
      setSharedIslands({ "island-1": islandData });
    });

    await waitFor(() => {
      expect(islandData.el).toHaveTextContent("5-test");
    });
  });

  test("wraps island in ContextProvider when provided", async () => {
    const { storeAccess, setSharedIslands, setProps } = createMockStoreAccess();

    const ContextProvider: React.FC<{ children: React.ReactNode }> = ({
      children,
    }) => <div data-context="wrapper">{children}</div>;

    render(<PortalIslandsRenderer storeAccess={storeAccess} />);

    const islandData = createMockIslandData({
      id: "island-1",
      ContextProvider,
    });

    act(() => {
      setProps("island-1", { count: 0 });
      setSharedIslands({ "island-1": islandData });
    });

    await waitFor(() => {
      const wrapper = islandData.el.querySelector('[data-context="wrapper"]');
      expect(wrapper).toBeInTheDocument();
      expect(islandData.el).toHaveTextContent("Count: 0");
    });
  });

  test("updates when props change in store", async () => {
    const { storeAccess, setSharedIslands, setProps } = createMockStoreAccess();

    render(<PortalIslandsRenderer storeAccess={storeAccess} />);

    const islandData = createMockIslandData({ id: "island-1" });

    act(() => {
      setProps("island-1", { count: 0 });
      setSharedIslands({ "island-1": islandData });
    });

    await waitFor(() => {
      expect(islandData.el).toHaveTextContent("Count: 0");
    });

    act(() => {
      setProps("island-1", { count: 5 });
    });

    await waitFor(() => {
      expect(islandData.el).toHaveTextContent("Count: 5");
    });
  });

  test("updates when globals change in store", async () => {
    const { storeAccess, setSharedIslands, setProps, setGlobals } = createMockStoreAccess();

    const MockComponent = ({ user }: any) => <div>User: {user}</div>;

    render(<PortalIslandsRenderer storeAccess={storeAccess} />);

    const islandData = createMockIslandData({
      id: "island-1",
      Component: MockComponent,
      globalKeys: ["user"],
    });

    act(() => {
      setGlobals({ user: "Alice", __version: 1 });
      setProps("island-1", {});
      setSharedIslands({ "island-1": islandData });
    });

    await waitFor(() => {
      expect(islandData.el).toHaveTextContent("User: Alice");
    });

    act(() => {
      setGlobals({ user: "Bob", __version: 2 });
    });

    await waitFor(() => {
      expect(islandData.el).toHaveTextContent("User: Bob");
    });
  });
});
