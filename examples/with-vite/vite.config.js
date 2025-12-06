import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  build: {
    // Output to Phoenix's priv/static/assets directory
    outDir: '../priv/static/assets',
    emptyOutDir: true,
    manifest: true,
    rollupOptions: {
      input: 'src/main.jsx'
    }
  },
  // Configure dev server for Phoenix integration
  server: {
    port: 5173,
    strictPort: true,
    // Allow Phoenix to proxy to Vite dev server
    cors: true,
    hmr: {
      host: 'localhost',
      protocol: 'ws'
    }
  }
})
