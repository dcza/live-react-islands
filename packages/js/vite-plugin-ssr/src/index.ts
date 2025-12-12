import type { Plugin, ViteDevServer } from "vite";

export interface LiveReactIslandsSSROptions {
  /**
   * Path to the SSR entry file (relative to project root)
   * This file should call exposeSSR() from @live-react-islands/core/ssr
   * @default "./src/ssr.js"
   */
  ssrEntry?: string;

  /**
   * SSR endpoint path
   * @default "/__ssr"
   */
  endpoint?: string;
}

interface SSRRequest {
  component: string;
  id: string;
  props: Record<string, any>;
  globals: Record<string, any>;
}

interface SSRModule {
  renderSSRIslandStatic: (
    component: string,
    id: string,
    props: Record<string, any>,
    globals: Record<string, any>
  ) => string;
}

/**
 * Vite plugin for LiveReactIslands SSR development server
 *
 * Adds a middleware endpoint that handles SSR requests from Elixir's ViteRenderer.
 * Uses Vite's HMR-enabled module loading for instant feedback during development.
 *
 * @example
 * ```ts
 * // vite.config.js
 * import { defineConfig } from "vite";
 * import react from "@vitejs/plugin-react";
 * import liveReactIslandsSSR from "@live-react-islands/vite-plugin-ssr";
 *
 * export default defineConfig({
 *   plugins: [
 *     react(),
 *     liveReactIslandsSSR({
 *       ssrEntry: "./src/ssr.js",
 *     }),
 *   ],
 * });
 * ```
 */
export default function liveReactIslandsSSR(
  options: LiveReactIslandsSSROptions = {}
): Plugin {
  const ssrEntry = options.ssrEntry || "./src/ssr.js";
  const endpoint = options.endpoint || "/__ssr";

  return {
    name: "live-react-islands-ssr",

    configureServer(server: ViteDevServer) {
      server.middlewares.use(async (req, res, next) => {
        // Only handle POST requests to our SSR endpoint
        if (req.method !== "POST" || req.url !== endpoint) {
          return next();
        }

        try {
          // Parse request body
          const chunks: Buffer[] = [];
          for await (const chunk of req) {
            chunks.push(Buffer.from(chunk));
          }
          const body = JSON.parse(Buffer.concat(chunks).toString());

          const { component, id, props, globals } = body as SSRRequest;

          // Validate request
          if (!component || !id) {
            res.statusCode = 400;
            res.setHeader("Content-Type", "application/json");
            res.end(
              JSON.stringify({
                error: "Missing required fields: component and id",
              })
            );
            return;
          }

          // Load the SSR module using Vite's HMR-enabled loader
          // This ensures we always get the latest version during development
          await server.ssrLoadModule(ssrEntry);

          // Access the global SSR_MODULE exposed by exposeSSR()
          const ssrModule = (globalThis as any).SSR_MODULE as
            | SSRModule
            | undefined;

          if (!ssrModule || !ssrModule.renderSSRIslandStatic) {
            res.statusCode = 500;
            res.setHeader("Content-Type", "application/json");
            res.end(
              JSON.stringify({
                error: `SSR module not found. Make sure ${ssrEntry} calls exposeSSR() from @live-react-islands/core/ssr`,
              })
            );
            return;
          }

          // Render the component
          const html = ssrModule.renderSSRIslandStatic(
            component,
            id,
            props || {},
            globals || {}
          );

          // Return the rendered HTML
          res.statusCode = 200;
          res.setHeader("Content-Type", "application/json");
          res.end(JSON.stringify({ html }));
        } catch (error: any) {
          console.error("[live-react-islands-ssr] Error rendering component:", error);

          res.statusCode = 500;
          res.setHeader("Content-Type", "application/json");
          res.end(
            JSON.stringify({
              error: error.message || "Unknown error during SSR",
              stack: error.stack,
            })
          );
        }
      });

      console.log(
        `[live-react-islands-ssr] SSR endpoint available at ${endpoint}`
      );
    },
  };
}
