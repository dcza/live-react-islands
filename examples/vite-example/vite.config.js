import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import liveReactIslandsSSR from "@live-react-islands/vite-plugin-ssr";

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
    liveReactIslandsSSR({
      ssrEntry: "./src/ssr.js",
    }),
  ],
  server: {
    host: "127.0.0.1",
    port: 5173,
    strictPort: true,
  },
  build: {
    target: "esnext",
    outDir: "./priv/static/assets",
    emptyOutDir: true,
    manifest: false,
    rollupOptions: {
      input: {
        // Client side bundle added to the phoenix root layout
        main: "./src/main.jsx",
        // Server side rendering bundle
        ssr: "./src/ssr.js",
      },
      output: {
        // Only main.js/css and ssr.js are static
        entryFileNames(chunk) {
          if (chunk.name === "main") return "main.js";
          if (chunk.name === "ssr") return "ssr.js";
          return "[name]-[hash].js";
        },
        chunkFileNames: "[name]-[hash].js",
        assetFileNames(assetInfo) {
          if (assetInfo.name === "main.css") return "main.css";
          return "[name]-[hash].[ext]";
        },
      },
    },
  },
});
