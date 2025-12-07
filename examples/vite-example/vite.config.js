import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  base: "/assets/",
  build: {
    target: "esnext",
    outDir: "./priv/static/assets",
    emptyOutDir: true,
    manifest: false,
    rollupOptions: {
      input: {
        main: "./src/main.jsx",
      },
      output: {
        entryFileNames: "[name].js",
        chunkFileNames: "[name].js",
        assetFileNames: "[name].[ext]",
      },
    },
  },
});
