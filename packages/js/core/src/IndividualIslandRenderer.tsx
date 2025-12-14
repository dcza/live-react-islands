import React, { forwardRef, useImperativeHandle, useState } from "react";
import type {
  IndividualIslandsRendererHandle,
  IndividualIslandsRendererProps,
} from "./types";

export const IndividualIslandRenderer = forwardRef<
  IndividualIslandsRendererHandle,
  IndividualIslandsRendererProps
>(({ data }, ref) => {
  const { Component, ContextProvider, id, pushEvent } = data;
  const [props, setProps] = useState(data.props);

  // Expose methods via ref
  useImperativeHandle(ref, () => ({
    update: (p) => setProps((prev) => ({ ...prev, ...p })),
  }));

  const islandNode = <Component {...props} id={id} pushEvent={pushEvent} />;
  return ContextProvider ? (
    <ContextProvider>{islandNode}</ContextProvider>
  ) : (
    islandNode
  );
});
