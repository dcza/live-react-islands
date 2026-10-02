import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import liveReactIslandsSSR from "@live-react-islands/vite-plugin-ssr";

// https://vite.dev/config/
export default defineConfig(({ command }) => ({
  base: command === "build" ? "/assets/" : "/",
  plugins: [
    react(),
    tailwindcss(),
    liveReactIslandsSSR({
      ssrEntry: "./src/ssr.js",
    }),
  ],
  builder: {},
  environments: {
    ssr: {
      build: {
        ssr: "./src/ssr.js",
        target: "esnext",
        outDir: "../priv/static/assets",
        emptyOutDir: false,
        rollupOptions: {
          input: "./src/ssr.js",
          output: {
            codeSplitting: true,
            manualChunks(id) {
              if (id.includes("node_modules")) return "ssr-vendor";
            },
            entryFileNames: "ssr.js",
            chunkFileNames: "[name]-[hash].js",
            assetFileNames: "[name]-[hash].[ext]",
          },
        },
      },
    },
  },
  server: {
    host: "127.0.0.1",
    port: 5173,
    strictPort: true,
  },
  build: {
    target: "esnext",
    outDir: "../priv/static/assets",
    emptyOutDir: true,
    manifest: false,
    rollupOptions: {
      input: { main: "./src/main.jsx" },
      output: {
        entryFileNames(chunk) {
          if (chunk.name === "main") return "main.js";
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
  ssr: {
    target: "webworker",
    noExternal: true,
  },
}));
