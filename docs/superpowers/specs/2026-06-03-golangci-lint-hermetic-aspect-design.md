# Hermetic golangci-lint aspect for rules_lint — Design

**Date:** 2026-06-03
**Status:** Approved design, pending spec review
**Author:** brainstormed with Claude

## Goal

Add golangci-lint — the de-facto "full" Go meta-linter (bundling staticcheck,
govet, errcheck, gosimple, ineffassign, etc.) — to rules_lint as a first-class
linter aspect, on par with the existing linters (shellcheck, ruff, eslint, …).

Go currently has only formatters in rules_lint (gofmt/gofumpt) and no linter.

The integration must be **hermetic**: a real Bazel action per Go package, with
no runtime `bazel query`/`bazel build` calls, no network, and no host module
cache. This makes it RBE-executable and remote-cacheable. It will most often
run on a CI runner backed by a remote cache rather than on RBE proper; the
hermetic design is a strict superset that runs identically in all three places.

## Why this is non-trivial (the core constraint)

golangci-lint loads packages through `golang.org/x/tools/go/packages`, which is
**type-aware**: to run staticcheck/govet/errcheck it must typecheck each package
*together with its dependencies*. By default `go/packages` shells out to
`go list`/`go build`, which a hermetic sandbox forbids (no network, no module
cache).

rules_go ships a `gopackagesdriver`, but the **stock driver is not usable inside
a sandboxed action**: at runtime it shells out to `bazel query` and `bazel build`
to discover and compile packages (`bazel.go`, `bazel_json_builder.go`). That is
bazel-in-bazel and requires a live Bazel server + workspace root, which the
sandbox denies. This was confirmed against the fetched rules_go source and
matches the community consensus (rules_go #2695, golangci-lint #1473): nobody
runs stock golangci-lint hermetically this way.

### Approaches considered

- **A. Static-metadata driver (CHOSEN).** A rules_lint aspect pre-computes each
  package's metadata + dependency export data as *declared action inputs*, plus
  a custom file-reading `GOPACKAGESDRIVER` that reads those pre-staged files and
  never calls bazel. Feeds the real golangci-lint binary. Fully hermetic,
  RBE/remote-cache friendly, per-target. Highest effort (we ship a packages
  driver) but the only path that is both real golangci-lint *and* hermetic.
- **B. `bazel run` tool.** Real golangci-lint, low effort, runs over the whole
  module outside the sandbox using the stock driver / `go list`. Not hermetic,
  not cacheable, not per-target. Rejected: gives up the caching we explicitly
  want.
- **C. nogo analyzers.** Assemble golangci-lint's underlying `go/analysis`
  analyzers into a rules_go `nogo` binary. Natively hermetic but it is a
  build-time gate, not a rules_lint aspect, and is *not* the golangci-lint
  binary (AST-only linters that don't expose an `analysis.Analyzer` don't port).
  Rejected: doesn't deliver "golangci-lint as a rules_lint linter."

## Key enabling finding

rules_go's `gopackagesdriver` cleanly separates two halves:

- **Bazel-calling half** — `BazelJSONBuilder.Labels()`/`.Build()`
  (`bazel_json_builder.go`): runs `bazel query`/`bazel build`. **We discard this.**
- **Read + assemble half** — `JSONPackagesDriver`, `PackageRegistry`,
  `WalkFlatPackagesFromJSON`, `GetResponse()`
  (`json_packages_driver.go`, `packageregistry.go`, `flatpackage.go`): ingests
  per-package `.pkg.json` files and emits the `go/packages` `DriverResponse`.
  **We keep this.**

And `go_pkg_info_aspect`
(`@io_bazel_rules_go//go/tools/gopackagesdriver:aspect.bzl`) already emits exactly
the metadata we need, via `OutputGroupInfo`:

- `go_pkg_driver_json_file` — per-package `.pkg.json` (direct + transitive)
- `go_pkg_driver_export_file` — compiled `.x` export data (direct + transitive)
- `go_pkg_driver_srcs` — compiled `.go` source files (direct + transitive)
- `go_pkg_driver_stdlib_json_file` — stdlib package metadata
- `go_pkg_driver_stdlib_cache_dir` — stdlib export/cache

**Export data alone is sufficient to typecheck dependents** — we never stage
dependency *source*, only `.x` files. This is both correct and the foundation of
the caching story (see below).

## Architecture

```
                  go_library / go_binary / go_test target
                                  │
        ┌─────────────────────────┴──────────────────────────┐
        │  lint_golangci_lint_aspect  (lint/golangci_lint.bzl)│
        │  • requires = [go_pkg_info_aspect]                   │
        │  • reads GoPkgInfo OutputGroupInfo depsets:          │
        │    .pkg.json, .x export files, stdlib json/cache     │
        └─────────────────────────┬──────────────────────────┘
                                  │ one hermetic action per package
                                  ▼
   ┌───────────────────────────────────────────────────────────────┐
   │ Action: golangci-lint run <pkg>                                 │
   │   env GOPACKAGESDRIVER = ./static_driver                        │
   │       GOPACKAGESDRIVER_JSON_DIR = <staged dir of .pkg.json>     │
   │       GOCACHE / GOLANGCI_LINT_CACHE = <sandbox tmp>             │
   │   inputs:                                                       │
   │     • golangci-lint binary  (@multitool → //lint:golangci_…)   │
   │     • static_driver binary  (lint/private, go_binary)          │
   │     • this package's .go srcs (CompiledGoFiles)                │
   │     • transitive dep .x export files                          │
   │     • transitive .pkg.json + stdlib json/cache                │
   │     • .golangci.yml config                                     │
   │   outputs: human report + exit_code, machine SARIF report      │
   └───────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
       golangci-lint → go/packages.Load() → execs $GOPACKAGESDRIVER
                                  │ stdin: DriverRequest JSON
                                  ▼
   ┌───────────────────────────────────────────────────────────────┐
   │ static_driver  (lint/private/gopackagesdriver_static/)         │
   │   • forks rules_go READ half: flatpackage.go,                  │
   │     packageregistry.go, json_packages_driver.go                │
   │   • new main.go: glob pre-staged .pkg.json from                │
   │     $GOPACKAGESDRIVER_JSON_DIR (NO bazel calls)               │
   │   • resolves __BAZEL_EXECROOT__/__BAZEL_OUTPUT_BASE__ → cwd     │
   │   • writes DriverResponse JSON to stdout                       │
   └───────────────────────────────────────────────────────────────┘
```

golangci-lint believes it is loading packages normally; its package driver is
our static binary reading files Bazel already staged into the sandbox as
declared inputs. No bazel-in-bazel, no network, no module cache.

## Components

### A. Static driver — `lint/private/gopackagesdriver_static/`

- A `go_binary` built in-repo via rules_go (already in root `MODULE.bazel`).
- **Vendored fork** of three read-half files from rules_go's
  `go/tools/gopackagesdriver/`: `flatpackage.go`, `packageregistry.go`,
  `json_packages_driver.go`. These are `package main` internals and not
  importable, so a copy is the realistic option. A header comment pins the
  rules_go version copied from, for future re-syncs.
- New `main.go`:
  - Reads `packages.DriverRequest` from stdin.
  - Discovers pre-staged `.pkg.json` files from `$GOPACKAGESDRIVER_JSON_DIR`
    (a directory, or a manifest file listing paths).
  - Assembles `packages.DriverResponse` via the reused registry logic.
  - Resolves `__BAZEL_EXECROOT__` / `__BAZEL_OUTPUT_BASE__` placeholders to the
    action's cwd (the sandbox execroot).
  - Writes the response JSON to stdout. **No bazel calls.**
- Emitted `DriverResponse` carries the `FlatPackage` fields rules_go already
  produces: `ID`, `Name`, `PkgPath`, `GoFiles`, `CompiledGoFiles`, `OtherFiles`,
  `ExportFile`, `Imports`, `Standard`, `Errors`.

### B. The aspect — `lint/golangci_lint.bzl`

- Public factory `lint_golangci_lint_aspect(binary, config, rule_kinds=...)`,
  mirroring the existing linter factories (`lint_shellcheck_aspect`, etc.).
- Visits `["go_library", "go_binary", "go_test"]` by default (overridable via
  `rule_kinds`, matching repo convention).
- `requires = [go_pkg_info_aspect]` so rules_go generates the metadata; the impl
  reads the target's `GoPkgInfo` provider and its `OutputGroupInfo` depsets. **We
  do not reimplement metadata generation.**
- Stages those depsets as action inputs (transitive `.pkg.json`, `.x`, stdlib).
- Follows the existing `output_files` / `patch_and_output_files` helpers from
  `//lint/private:lint_aspect.bzl`. golangci-lint supports `--fix`, so patch
  mode produces a fix diff like other linters.
- Honors `//lint:options` (`color`, `debug`, `fail_on_violation`, `fix`).

### C. Tool provisioning

- golangci-lint prebuilt binary added to `lint/multitool.lock.json` (the repo's
  existing mechanism for ruff/shellcheck/ty), exposed as `//lint:golangci_lint_bin`
  via an alias in `lint/BUILD.bazel`. golangci-lint ships per-OS/arch release
  tarballs, so multitool fits.
- Pin a **minimum golangci-lint version** that supports both a custom
  `GOPACKAGESDRIVER` and native SARIF output (see Risks).

### D. Configuration

- `config = Label("//:.golangci.yml")` attribute on the aspect, passed to
  golangci-lint via `--config`, mirroring how `.shellcheckrc` and other config
  files are threaded into actions elsewhere.

### E. SARIF output

- golangci-lint has **native** SARIF output (`--output.sarif.path`, older
  `--out-format sarif`). We write the machine report directly and **skip**
  `parse_to_sarif_action` entirely.
- The SARIF must contain **workspace-relative** paths (see Cache reuse #3).

### F. Example + test — `examples/go/`

- New example dir matching the structure of every other example
  (`MODULE.bazel`, `.bazelrc`, `BUILD`, `README.md`, `tools/lint/linters.bzl`,
  `test/`).
- `go_library` targets: one clean, one with a staticcheck/govet-triggering bug.
- `tools/lint/linters.bzl` wires `lint_golangci_lint_aspect`.
- A `lint_test` (via `//lint:lint_test.bzl`) asserting expected findings, plus
  the machine-output snapshot test other examples use.

## Cache reuse

Maximizing cache reuse — including shared/remote cache hits across CI runners and
machines — is an explicit goal. Four design points:

1. **Per-package action granularity.** One action per `go_*` target, never a
   single module-wide lint. Only packages whose inputs change are re-linted.
   This is the finest sensible granularity.

2. **Export-data (`.x`) invalidation, not source invalidation.** Dependencies are
   staged as content-addressed `.x` export files keyed on the package's *public
   interface*. An implementation-only change in a dependency yields an identical
   `.x` → **no cache invalidation** for dependents. A dependent re-lints only
   when a dep's interface actually changes (which genuinely can change its lint
   result). Staging dep *source* would over-invalidate; we deliberately do not.

3. **Portable cache keys for cross-machine sharing.** Inputs carry rules_go's
   `__BAZEL_EXECROOT__` placeholders (resolved by the driver at runtime), so
   input content is machine-independent. The **SARIF output must use
   workspace-relative paths**, not sandbox-absolute ones; otherwise two machines
   produce different output bytes and never share a remote-cache entry. Normalize
   if golangci-lint bakes in absolute paths (see Risks).

4. **Sandbox-local tool caches.** Set `GOCACHE` / `GOLANGCI_LINT_CACHE` to a
   sandbox temp dir so the action neither reads nor pollutes `$HOME`. We rely on
   Bazel's action cache, not golangci-lint's internal incremental cache.

## Risks / validate-with-a-prototype-first

These three are the assumptions most likely to break the design and should be
proven with a throwaway prototype before full implementation:

1. **`requires = [go_pkg_info_aspect]` reuse.** Confirm the `GoPkgInfo` provider
   and its `OutputGroupInfo` depsets are readable from a downstream aspect, and
   that `go_pkg_info_aspect` is loadable/public from
   `@io_bazel_rules_go//go/tools/gopackagesdriver:aspect.bzl`.

2. **golangci-lint honors a custom file-only `GOPACKAGESDRIVER`.** Verify
   golangci-lint loads via `go/packages` with our driver and successfully
   typechecks a package from export-data-only deps + stdlib metadata — including
   that it does not separately invoke `go list`/`go env` for state we haven't
   provided (set `GOROOT`, `GOFLAGS`, and stdlib inputs as needed).

3. **Native SARIF with relative paths.** Confirm the pinned golangci-lint version
   emits SARIF and that paths are workspace-relative (or post-process to make
   them so), so remote-cache entries are shareable across machines.

## Out of scope (YAGNI)

- gofmt/gofumpt formatting (already exists separately in rules_lint).
- nogo / build-time analyzer integration (Approach C).
- Custom golangci-lint plugin compilation (module plugin system).
- Editor/gopls integration (the stock `bazel run` driver already serves that
  outside this work).

## Implementation order (for the plan)

1. Prototype the three risks above end-to-end on a tiny Go package (throwaway).
2. Static driver: vendor read-half + `main.go`, build as `go_binary`, unit-test
   the stdin/stdout protocol against fixture `.pkg.json` files.
3. Tool provisioning: add golangci-lint to `multitool.lock.json` + alias.
4. The aspect: `lint/golangci_lint.bzl` + `bzl_library` wiring in
   `lint/BUILD.bazel`.
5. Example + lint_test under `examples/go/`.
6. Docs: add Go linter row to README supported-tools table; docsite update
   prompted separately per repo convention.
