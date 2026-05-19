# Release Plan for live-react-islands

This document outlines the steps needed to set up automated releases for all packages in this monorepo.

## Current State

### Packages to Release

**npm (JavaScript):**

- `@live-react-islands/core` (v0.1.0)
- `@live-react-islands/vite-plugin-ssr` (v0.1.0)

**Hex.pm (Elixir):**

- `live_react_islands` (v0.1.0)
- `live_react_islands_ssr_vite` (v0.1.0)
- `live_react_islands_ssr_deno` (v0.1.0)

### What Exists

- Yarn workspaces configured
- Build scripts (`yarn build`, `yarn build:js`, `yarn build:elixir`)
- Test scripts (`yarn test`, `yarn test:js`, `yarn test:elixir`)
- Package configs ready for publishing (Hex and npm)
- CHANGELOG.md exists

### What's Missing

- GitHub Actions CI/CD
- Automated version management
- Publishing scripts
- Credentials/secrets setup

---

## Phase 1: CI Pipeline (GitHub Actions)

### 1.1 Create `.github/workflows/ci.yml`

Basic CI to run on every PR and push to main:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test-js:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "24"
          cache: "yarn"
      - run: corepack enable
      - run: yarn install --immutable
      - run: yarn build:js
      - run: yarn test:js

  test-elixir:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: "27"
          elixir-version: "1.18"
      - run: yarn test:elixir
```

### 1.2 Add Linting/Formatting Checks

- Add ESLint + Prettier for JS packages
- Add `mix format --check-formatted` for Elixir
- Add Credo for Elixir static analysis

---

## Phase 2: Version Management

### Option A: Manual Versioning (Simple)

Keep current approach but document the process:

1. Update version in each `package.json` and `mix.exs`
2. Update CHANGELOG.md
3. Create git tag
4. Push and let CI publish

### Option B: Changesets (Recommended for Monorepos)

Install and configure `@changesets/cli`:

```bash
yarn add -D @changesets/cli
yarn changeset init
```

Workflow:

1. Contributors run `yarn changeset` when making changes
2. CI creates "Version Packages" PR aggregating changesets
3. Merging that PR bumps versions and updates changelog

**Note:** Changesets is JS-focused. For Elixir packages, we'd need a custom script to sync versions from JS or maintain separately.

### Option C: Manual Tags with Automated Publishing

Use git tags as the source of truth:

- Tag format: `v1.2.3` for all packages (unified versioning)
- Or: `core@1.2.3`, `vite-plugin@1.2.3`, `elixir@1.2.3` for independent versioning

---

## Phase 3: Release Workflows

### 3.1 NPM Publishing Workflow

Create `.github/workflows/publish-npm.yml`:

```yaml
name: Publish NPM Packages

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          registry-url: "https://registry.npmjs.org"
          cache: "yarn"
      - run: corepack enable
      - run: yarn install --immutable
      - run: yarn build:js
      - run: yarn test:js

      # Publish core first (no internal deps)
      - run: cd packages/js/core && npm publish --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}

      # Then publish vite-plugin
      - run: cd packages/js/vite-plugin-ssr && npm publish --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**Required Secret:** `NPM_TOKEN`

- Generate at: https://www.npmjs.com/settings/YOUR_USER/tokens
- Add to: GitHub repo → Settings → Secrets → Actions

### 3.2 Hex.pm Publishing Workflow

Create `.github/workflows/publish-hex.yml`:

```yaml
name: Publish Hex Packages

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: "26"
          elixir-version: "1.16"

      - name: Publish live_react_islands
        working-directory: packages/elixir/live_react_islands
        run: |
          mix deps.get
          mix hex.publish --yes
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}

      - name: Publish live_react_islands_ssr_vite
        working-directory: packages/elixir/live_react_islands_ssr_vite
        run: |
          mix deps.get
          mix hex.publish --yes
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}

      - name: Publish live_react_islands_ssr_deno
        working-directory: packages/elixir/live_react_islands_ssr_deno
        run: |
          mix deps.get
          mix hex.publish --yes
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
```

**Required Secret:** `HEX_API_KEY`

- Generate at: https://hex.pm/settings/keys
- Add to: GitHub repo → Settings → Secrets → Actions

---

## Phase 4: Release Process Documentation

### Manual Release Checklist

1. **Prepare Release**

   ```bash
   # Ensure main is up to date
   git checkout main && git pull

   # Run all tests
   yarn test

   # Build all packages
   yarn build
   ```

2. **Update Versions**

   JavaScript packages:

   - `packages/js/core/package.json`
   - `packages/js/vite-plugin-ssr/package.json`

   Elixir packages:

   - `packages/elixir/live_react_islands/mix.exs`
   - `packages/elixir/live_react_islands_ssr_vite/mix.exs`
   - `packages/elixir/live_react_islands_ssr_deno/mix.exs`

3. **Update CHANGELOG.md**

   - Add new version section with date
   - List all changes since last release

4. **Commit and Tag**

   ```bash
   git add -A
   git commit -m "Release v0.2.0"
   git tag v0.2.0
   git push origin main --tags
   ```

5. **Create GitHub Release**
   - Go to GitHub → Releases → Create new release
   - Select the tag
   - Copy changelog entries as release notes
   - Publish release → triggers CI publishing

---

## Phase 5: Advanced Improvements (Future)

### 5.1 Version Sync Script

Create a script to update all package versions from a single source:

```bash
#!/bin/bash
# scripts/set-version.sh
VERSION=$1

# JS packages
sed -i '' "s/\"version\": \".*\"/\"version\": \"$VERSION\"/" packages/js/core/package.json
sed -i '' "s/\"version\": \".*\"/\"version\": \"$VERSION\"/" packages/js/vite-plugin-ssr/package.json

# Elixir packages
sed -i '' "s/@version \".*\"/@version \"$VERSION\"/" packages/elixir/live_react_islands/mix.exs
sed -i '' "s/@version \".*\"/@version \"$VERSION\"/" packages/elixir/live_react_islands_ssr_vite/mix.exs
sed -i '' "s/@version \".*\"/@version \"$VERSION\"/" packages/elixir/live_react_islands_ssr_deno/mix.exs

echo "Updated all packages to version $VERSION"
```

### 5.2 Pre-release Validation

Add a workflow that runs when a release tag is pushed but before publishing:

- Verify all packages have matching versions
- Run full test suite
- Build and dry-run publish

### 5.3 Independent Versioning

If packages need different versions, use scoped tags:

- `core@1.0.0`
- `vite-plugin@1.0.0`
- `elixir@1.0.0`

And filter in workflows based on tag prefix.

---

## Implementation Priority

| Priority | Task                                        | Effort |
| -------- | ------------------------------------------- | ------ |
| 1        | Create CI workflow (test on PR)             | Low    |
| 2        | Add NPM_TOKEN and HEX_API_KEY secrets       | Low    |
| 3        | Create publish-npm workflow                 | Low    |
| 4        | Create publish-hex workflow                 | Low    |
| 5        | Document release process in CONTRIBUTING.md | Low    |
| 6        | Add version sync script                     | Medium |
| 7        | Set up Changesets (optional)                | Medium |
| 8        | Add pre-release validation                  | Medium |

---

## Quick Start Commands

```bash
# After setting up workflows and secrets, releasing is:

# 1. Update versions
./scripts/set-version.sh 0.2.0

# 2. Update CHANGELOG.md (manually)

# 3. Commit, tag, push
git add -A && git commit -m "Release v0.2.0"
git tag v0.2.0
git push origin main --tags

# 4. Create GitHub Release (triggers publishing)
gh release create v0.2.0 --notes "See CHANGELOG.md for details"
```
