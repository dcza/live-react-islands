import resolve from "@rollup/plugin-node-resolve";
import commonjs from "@rollup/plugin-commonjs";
import typescript from "@rollup/plugin-typescript";

export default [
  // Browser/client build
  {
    input: "src/index.ts", // client-safe entry
    output: [
      {
        file: "dist/index.js",
        format: "cjs",
        sourcemap: true,
      },
      {
        file: "dist/index.esm.js",
        format: "esm",
        sourcemap: true,
      },
    ],
    external: ["react", "react-dom", "phoenix", "phoenix_live_view"],
    plugins: [
      resolve(),
      commonjs(),
      typescript({
        tsconfig: "./tsconfig.json",
        declaration: true,
        declarationDir: "./dist",
      }),
    ],
  },

  // SSR build
  {
    input: "src/ssr.ts", // Node-only entry
    output: [
      {
        file: "dist/ssr.js",
        format: "cjs",
        sourcemap: true,
      },
      {
        file: "dist/ssr.esm.js",
        format: "esm",
        sourcemap: true,
      },
    ],
    external: ["react", "react-dom/server", "phoenix", "phoenix_live_view"],
    plugins: [
      resolve(),
      commonjs(),
      typescript({
        tsconfig: "./tsconfig.json",
        declaration: true,
        declarationDir: "./dist",
      }),
    ],
  },
];
