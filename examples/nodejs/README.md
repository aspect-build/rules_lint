# Node.js Formatting and Linting Example

This example demonstrates how to set up formatting and linting for Node.js ecosystem files (JavaScript, TypeScript, Vue, CSS, LESS, SCSS, HTML, Markdown) using `rules_lint`.

## Supported Tools

### Formatters

- **Prettier** - Code formatter for JavaScript, TypeScript, CSS, LESS, SCSS, HTML, and Markdown

### Linters

- **ESLint** - JavaScript and TypeScript linter
- **Stylelint** - CSS linter
- **Vale** - Markdown linter

## Setup

### 1. Configure MODULE.bazel

Add the required dependencies:

```starlark
bazel_dep(name = "aspect_rules_lint")
bazel_dep(name = "aspect_rules_js", version = "2.0.0")
bazel_dep(name = "aspect_rules_swc", version = "2.0.0")
bazel_dep(name = "aspect_rules_ts", version = "3.0.0")
bazel_dep(name = "bazel_features", version = "1.29.0")
```

### 2. Set up npm dependencies

Install npm dependencies and generate the lock file:

```bash
pnpm install
```

This will create `pnpm-lock.yaml` based on `package.json`.

### 3. Configure Formatters and Linters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up each linter aspect

### 4. Run Formatters and Linters

With Aspect CLI:

```bash
# Format code
bazel format //src:all

# Lint code
bazel lint //src:all
```

Without Aspect CLI:

```bash
# Format code
bazel run //tools/format:format

# Lint code (use lint.sh script)
./lint.sh src:all
```

## Example Code

The `src/` directory contains example files with intentional violations:

- `hello.js` - Simple JavaScript file
- `file.ts`, `file-dep.ts` - TypeScript files with ESLint violations
- `hello.tsx` - React TypeScript file
- `hello.vue` - Vue component
- `hello.css`, `clean.css` - CSS files (one with violations, one clean)
- `hello.less` - LESS file (CSS preprocessor)
- `hello.scss` - SCSS file (SASS CSS preprocessor)
- `index.html` - HTML file
- `README.md` - Markdown file with Vale violations

## Configuration Files

- `eslint.config.mjs` - ESLint configuration
- `stylelint.config.mjs` - Stylelint configuration
- `.vale.ini` - Vale configuration for Markdown
- `prettier.config.cjs` - Prettier configuration
- `tsconfig.json` - TypeScript configuration
- `.swcrc` - SWC (TypeScript/JavaScript compiler) configuration
