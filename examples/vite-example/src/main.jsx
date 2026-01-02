import "./index.css";
import { createHooks } from "@live-react-islands/core";
import islands from "./islands";

// Create the React Islands hooks
const islandHooks = createHooks({
  islands,
});

// Set up LiveView
import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },

  // Spread the hooks into your hooks object
  hooks: { /* Your other hooks  */ ...islandHooks },
});

liveSocket.connect();

window.liveSocket = liveSocket;
