# Task 0 spike findings — hermetic golangci-lint via static GOPACKAGESDRIVER

Date: 2026-06-03
Repo/branch: `rules_lint` @ `feat/golangci-lint-hermetic-aspect`
golangci-lint: **v2.12.2** (built with go1.25.5), invoked from `/Users/mcramer/go/bin/golangci-lint`
Go: go1.25.5 (host); bazel go_sdk used for the run is **go1.23.9** (rules_go pinned SDK)
Spike target: `//tools/sarif:sarif` (a `go_library`; transitive deps: protobuf, reviewdog, etc.)
Throwaway artifacts: `/tmp/golangci-spike/` (driver, staged JSON, SARIF outputs). Not committed.

---

## VERDICT: the static-driver approach is VIABLE — with one required addition

A file-reading GOPACKAGESDRIVER that reads pre-staged `.pkg.json` and never calls
bazel at runtime **does** drive golangci-lint v2.12.2 to completion and produce real
findings via export-data-only typechecking — **but only after we inject `ExportFile`
values for stdlib packages.** Out of the box the rules_go aspect emits stdlib with
source files and **zero** export files, which causes golangci-lint to fail with
`could not load export data: no export data for "...stdlib:math/bits"`. Once stdlib
export files are supplied, typechecking succeeds across the whole graph with no
go-list/network fallback. Phase 2 must solve "where do stdlib export files come from"
and "rewrite SARIF URIs to workspace-relative".

---

## Assumption 1 — aspect reuse: CONFIRMED

`go_pkg_info_aspect` is loadable and emits the expected output groups.

```
bazel build --aspects=@io_bazel_rules_go//go/tools/gopackagesdriver:aspect.bzl%go_pkg_info_aspect \
  --output_groups=go_pkg_driver_json_file,go_pkg_driver_export_file,go_pkg_driver_stdlib_json_file //tools/sarif:sarif
# => Build completed successfully, 237 total actions
```

Output paths recorded (under `bazel-bin`, workspace `/Users/mcramer/Code/Aspect/rules_lint`):
- Per-target pkg.json: `bazel-bin/tools/sarif/sarif.pkg.json` (+ ~57 transitive-dep `*.pkg.json`)
- Export file: `bazel-bin/tools/sarif/sarif.x` (and a `.x` per non-stdlib dep)
- Stdlib JSON: `bazel-bin/external/rules_go~/stdlib_/stdlib.pkg.json` (294 stdlib pkgs, **0 with ExportFile**)
- **Fifth, undocumented-in-task output group** `go_pkg_driver_stdlib_cache_dir`
  => `bazel-bin/external/rules_go~/stdlib_/gocache` — a **Go build cache** (hashed `00`..`ff` dirs),
  NOT a GOROOT pkg tree, NOT `.a`/`.x` files. This is where stdlib export data actually lives.
  The real driver's default output groups include it (see `bazel_json_builder.go:164`).

---

## Placeholder strings (exact) — driver must resolve all THREE

From `bazel-bin/tools/sarif/sarif.pkg.json` and `stdlib.pkg.json`:

| Placeholder              | Appears in                          | Resolve to (`bazel info`)        |
|--------------------------|-------------------------------------|----------------------------------|
| `__BAZEL_EXECROOT__`     | `ExportFile` (non-stdlib `.x`)      | `execution_root`                 |
| `__BAZEL_WORKSPACE__`    | `GoFiles` / `CompiledGoFiles` (1st-party src) | `workspace`            |
| `__BAZEL_OUTPUT_BASE__`  | stdlib `GoFiles` (SDK src)          | `output_base`                    |

This matches upstream exactly (`bazel_json_builder.go:259-261`, each a single
`strings.Replace(..., 1)`). For this run:
- execution_root = `/private/var/tmp/_bazel_mcramer/86f5ef871ed2dc47ee08c98d356a6feb/execroot/_main`
- output_base    = `/private/var/tmp/_bazel_mcramer/86f5ef871ed2dc47ee08c98d356a6feb`
- workspace      = `/Users/mcramer/Code/Aspect/rules_lint`

### `.pkg.json` schema (FlatPackage)
`ID, Name, PkgPath, Errors, GoFiles, CompiledGoFiles, OtherFiles, ExportFile, Imports (map importpath->ID), Standard`.
Sample (first-party):
```json
{
  "ID": "@@//tools/sarif:sarif",
  "PkgPath": "github.com/aspect-build/rules_lint/tools/sarif",
  "ExportFile": "__BAZEL_EXECROOT__/bazel-out/darwin_arm64-fastbuild/bin/tools/sarif/sarif.x",
  "GoFiles": ["__BAZEL_WORKSPACE__/tools/sarif/sarif.go"],
  "CompiledGoFiles": ["__BAZEL_WORKSPACE__/tools/sarif/sarif.go"],
  "Imports": { "github.com/reviewdog/reviewdog/parser": "@@gazelle~~go_deps~com_github_reviewdog_reviewdog//parser:parser", ... }
}
```
Stdlib entries set `"Standard": true`, carry only `GoFiles`/`CompiledGoFiles` (SDK
sources under `__BAZEL_OUTPUT_BASE__/external/rules_go~~go_sdk~.../src/...`), and have
**no `ExportFile`**.

---

## Assumption 2 — export-data-only typecheck: CONFIRMED YES (with stdlib export injection)

### golangci-lint's DriverRequest (captured by wrapping the driver)
`mode = 8767` = `NeedName | NeedFiles | NeedCompiledGoFiles | NeedImports | NeedDeps |
NeedExportFile | NeedTypesSizes | NeedModule`. Crucially: `NeedExportFile` is SET while
`NeedTypes/NeedSyntax/NeedTypesInfo` are UNSET — golangci-lint does its **own**
typechecking from export data (`gcexportdata`) for dependencies, and only reads syntax
for the packages being linted. `tests:true`, `build_flags:["-buildvcs=false"]`.

### First attempt (no stdlib export) — FAILED, exact error:
```
typecheck: could not import math/bits (-: could not load export data:
no export data for "@@rules_go~//stdlib:math/bits")
```
Root cause: stdlib `.pkg.json` has empty `ExportFile` for all 294 stdlib packages
(verified: `withExportFile: 0`). protobuf imports `math/bits`; golangci-lint's importer
asks for its export file, finds none. Pointing `GOCACHE` at the bazel stdlib `gocache`
did **not** help, because the failure is "no `ExportFile` on the Package object", not
"cache miss" — the importer never consults GOCACHE for a package whose `ExportFile` is "".

### Fix that worked: inject stdlib `ExportFile`
The bazel-built stdlib `gocache` *does* contain stdlib export data. Resolve pkgpath ->
export-file once via:
```
GOROOT=<go_sdk> GOCACHE=<copy of bazel stdlib gocache> GOPROXY=off go list -export -json std
# => 300 std pkgs, e.g. math/bits -> <gocache>/5c/5c14...-d
```
The spike driver loads this map (`GOPACKAGESDRIVER_STDEXPORT_JSON`) and sets
`pkg.ExportFile` for every `registry.stdlib` package whose `PkgPath` is in the map.

### Result after fix — SUCCESS:
```
113 issues:  errcheck: 36   govet: 3   staticcheck: 47   unused: 27
exit=1   (exit 1 == "issues found", not a tool error)
```
- **Zero `typecheck` errors** — full transitive typecheck (protobuf, reviewdog, golang/protobuf, etc.) succeeded from export-data-only deps.
- **stderr empty across all 4 runs** — `grep -iE 'go list|cannot find|no required module|dial tcp|lookup .* no such host'` matched nothing. No go-list/network fallback occurred.
- First-party `//tools/sarif:sarif` typechecked clean (no findings of its own), confirming first-party source + dep export data compose correctly.

Required env for the successful run (env -i, only these set):
```
GOPACKAGESDRIVER=<static driver>
GOPACKAGESDRIVER_JSON_DIR=<dir of staged *.pkg.json incl stdlib>
GOPACKAGESDRIVER_EXECROOT=<bazel execution_root>
GOPACKAGESDRIVER_OUTPUT_BASE=<bazel output_base>
GOPACKAGESDRIVER_WORKSPACE=<bazel workspace>
GOPACKAGESDRIVER_STDEXPORT_JSON=<pkgpath->exportfile map>   # spike-only mechanism for stdlib export
GOROOT=<output_base>/external/rules_go~~go_sdk~main___download_0
GOFLAGS=-mod=mod   GOPROXY=off
GOCACHE=<writable copy of bazel stdlib gocache>
GOLANGCI_LINT_CACHE=<writable tmp>
HOME, PATH
```
Note `GOROOT` + `GOFLAGS=-mod=mod` + `GOPROXY=off` matter: without GOPROXY=off there is
risk of network module resolution; with it set, the run stayed fully offline.

---

## Assumption 3 — SARIF path portability: NOT portable out of the box (needs URI rewrite)

- Flag that works in v2.12.2: **`--output.sarif.path=<file>`** (confirmed in `run --help`).
- `artifactLocation.uri` values are **relative paths anchored to golangci-lint's CWD**,
  with deep `../` traversal into the bazel cache, e.g.
  `../../../../../private/var/tmp/_bazel_.../external/gazelle~~go_deps~.../proto/text_encode.go`.
  Changing CWD changed the number of `../` segments (7 from the package dir, 5 from workspace
  root) — confirming they are CWD-relative, not workspace-relative.
- There is **no `originalUriBaseIds`** and **no `invocation.workingDirectory`** in the run
  object, so a consumer cannot re-anchor the URIs without external knowledge of the CWD.
- First-party files resolve through `__BAZEL_WORKSPACE__` to the **real workspace source
  path** (`/Users/.../rules_lint/tools/sarif/sarif.go`), which is the good case — those can be
  made workspace-relative by stripping the workspace prefix. External-dep files point into
  the bazel cache and are inherently non-portable.

**Phase 2 implication:** a SARIF post-processing step is required to (a) make first-party
URIs workspace-relative and (b) decide how to present (or drop) findings in external-dep
sources, which live in the cache and have no stable workspace path.

---

## Query-arg -> package-ID mapping (Phase 2 depends on this)

In the **real** driver the mapping is done by `bazel query`, NOT by string matching:
`run()` (`main.go:94-99`) passes the CLI patterns to `BazelJSONBuilder.Labels()`, which
builds a query (`bazel_json_builder.go:131-154 queryFromRequests`):
- `file=<path>.go`  -> `fileQuery(f)` (a `bazel query` for the target owning that file)
- `./...`, abs path, local import -> `localQuery`: `kind("^(<kinds>) rule$", <reldir>:*)`
  or `<reldir>...`
- `builtin` / `std` -> the `RulesGoStdlibLabel` (`@io_bazel_rules_go//:stdlib`)
- otherwise (when `GOPACKAGESDRIVER_BAZEL_QUERY_SCOPE` set) -> `packageQuery` matching by
  `attr(importpath, ...)`.

`PackageRegistry.Match(labels)` (`packageregistry.go:122`) then matches **bazel labels**
(prefixing bare labels with `@` for Bazel >= 6), pulls the matched roots, adds any
`<label>_xtest` sibling, and walks `Imports` transitively. It does **not** understand
`./...` / `file=` — those must already be resolved to labels.

**Consequence for the static (bazel-free) driver:** there is no `bazel query` at lint time,
so the driver cannot translate `./...` or `file=foo.go` to labels itself. The spike side-stepped
this by ignoring the CLI args and treating **every non-stdlib package ID present in the staged
JSON as a root** (see `helpers.go RootLabels()`), relying on the *staging step* to scope which
targets' `.pkg.json` are present. Phase 2 must own this scoping decision explicitly — likely:
the Bazel aspect/rule stages exactly the first-party target(s) under lint (+ their dep JSON),
and the driver roots = the staged first-party package IDs. If `file=`/pattern fidelity is
needed, the label resolution must be precomputed at analysis time (in Starlark) and handed to
the driver, since runtime `bazel query` is explicitly off the table.

---

## Concrete asks for the real build (Phase 1/2)

1. Parameterize the three placeholders from `bazel info` (execroot / workspace / output_base).
2. **Stdlib export data is the load-bearing problem.** The aspect gives stdlib *sources* +
   a *build cache* (`go_pkg_driver_stdlib_cache_dir`) but no per-package `ExportFile`.
   golangci-lint needs `ExportFile` set on stdlib packages. Options to evaluate:
   - Have the driver synthesize stdlib `ExportFile` from the staged stdlib gocache (the spike
     did this via an offline `go list -export -json std` against that cache).
   - Or build stdlib export `.x` as a dedicated output group and reference them in the JSON.
3. Stage `go_pkg_driver_stdlib_cache_dir` (the gocache) alongside the JSON and point `GOCACHE`
   at a writable copy; set `GOROOT` to the rules_go SDK; set `GOPROXY=off`, `GOFLAGS=-mod=mod`.
4. Add a SARIF URI-rewrite post-step (workspace-relative for first-party; policy for ext deps).
5. Decide the query-arg->label scoping in Starlark; the runtime driver should just root on the
   staged first-party package IDs.
