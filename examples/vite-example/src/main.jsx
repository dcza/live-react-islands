import "./index.css";
import { createHooks } from "@live-react-islands/core";
import Counter from "./islands/Counter";

// Create the React Islands hooks
const islandHooks = createHooks({
  islands: { Counter },
  //globalStoreHandler: (data) => console.log("[globalStoreHandler]", data),
});

// Set up LiveView
import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },

  // Spread the hooks into your hooks object
  hooks: { /* Your other hooks  */ ...islandHooks },
});

liveSocket.connect();

window.liveSocket = liveSocket;
