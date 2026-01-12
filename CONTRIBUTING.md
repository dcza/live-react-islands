# Contributing to LiveReactIslands

Thank you for your interest in contributing to LiveReactIslands! This document provides guidelines for contributing to the project.

## Development Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/dcza/live-react-islands.git
   cd live-react-islands
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Build packages:**
   ```bash
   npm run build
   ```

4. **Run tests:**
   ```bash
   # JavaScript tests
   cd packages/js/core
   npm test

   # Elixir tests
   cd packages/elixir/live_react_islands
   mix test
   ```

## Project Structure

```
live-react-islands/
├── packages/
│   ├── js/
│   │   ├── core/                      # @live-react-islands/core
│   │   └── vite-plugin-ssr/           # @live-react-islands/vite-plugin-ssr
│   └── elixir/
│       ├── live_react_islands/        # Core Elixir package
│       ├── live_react_islands_ssr_vite/   # Vite SSR renderer (dev)
│       └── live_react_islands_ssr_deno/   # Deno SSR renderer (prod)
├── examples/
│   └── vite-example/                  # Example Phoenix app with Vite
└── docs/                              # Documentation
```

## Making Changes

1. **Create a branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - Write clear, concise commit messages
   - Add tests for new features
   - Update documentation as needed

3. **Test your changes:**
   ```bash
   cd packages/js/core && npm test
   cd packages/elixir/live_react_islands && mix test
   ```

4. **Submit a pull request:**
   - Provide a clear description of the changes
   - Reference any related issues
   - Ensure CI passes

## Code Style

### Elixir
- Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use `mix format` before committing

### JavaScript/TypeScript
- Use meaningful variable names
- Add JSDoc comments for public APIs
- Follow existing code patterns

## Reporting Issues

When reporting issues, please include:
- A clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your environment (Elixir version, Node version, etc.)

## Pull Request Process

1. Update the CHANGELOG.md with your changes
2. Update documentation if needed
3. Ensure all tests pass
4. Request review from maintainers

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
