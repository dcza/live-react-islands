#!/bin/bash
set -e

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "Usage: ./scripts/set-version.sh <version>"
  echo "Example: ./scripts/set-version.sh 0.2.0"
  exit 1
fi

# JS packages
sed -i '' "s/\"version\": \".*\"/\"version\": \"$VERSION\"/" packages/js/core/package.json
sed -i '' "s/\"version\": \".*\"/\"version\": \"$VERSION\"/" packages/js/vite-plugin-ssr/package.json

# Elixir packages
sed -i '' "s/@version \".*\"/@version \"$VERSION\"/" packages/elixir/live_react_islands/mix.exs
sed -i '' "s/@version \".*\"/@version \"$VERSION\"/" packages/elixir/live_react_islands_ssr_vite/mix.exs
sed -i '' "s/@version \".*\"/@version \"$VERSION\"/" packages/elixir/live_react_islands_ssr_deno/mix.exs

echo "Updated all packages to version $VERSION"
