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
    external: (id) => {
      return id === "react" ||
             id.startsWith("react/") ||
             id === "react-dom" ||
             id.startsWith("react-dom/") ||
             id === "phoenix" ||
             id === "phoenix_live_view";
    },
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
    external: (id) => {
      return id === "react" ||
             id.startsWith("react/") ||
             id === "react-dom" ||
             id.startsWith("react-dom/") ||
             id === "phoenix" ||
             id === "phoenix_live_view";
    },
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
