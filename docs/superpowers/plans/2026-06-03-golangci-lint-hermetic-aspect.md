# Hermetic golangci-lint aspect Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add golangci-lint to rules_lint as a hermetic, per-package, RBE/remote-cache-friendly linter aspect that visits `go_library`/`go_binary`/`go_test` targets.

**Architecture:** A rules_lint aspect (`requires = [go_pkg_info_aspect]`) reads rules_go's pre-computed per-package metadata (`.pkg.json`), transitive export data (`.x`), and stdlib metadata, stages them as action inputs, and runs the real golangci-lint binary against a **static file-reading `GOPACKAGESDRIVER`** — a vendored fork of rules_go's gopackagesdriver *read half* with the `bazel query`/`bazel build` half replaced by "glob pre-staged `.pkg.json` from a directory." No bazel-in-bazel, no network, no module cache.

**Tech Stack:** Bazel (Starlark aspects), rules_go (`@io_bazel_rules_go`), Go (the static driver binary), rules_multitool (golangci-lint binary provisioning), golangci-lint native SARIF output.

**Reference spec:** `docs/superpowers/specs/2026-06-03-golangci-lint-hermetic-aspect-design.md`

---

## File Structure

- `lint/private/gopackagesdriver_static/` — the static driver Go binary
  - `main.go` (new) — stdin/stdout driver protocol, reads pre-staged JSON, no bazel calls
  - `flatpackage.go`, `packageregistry.go`, `json_packages_driver.go`, `driver_request.go`, `utils.go` (vendored verbatim from rules_go)
  - `BUILD.bazel` (new) — `go_binary` + `go_test`
  - `main_test.go` (new) — protocol unit test against fixture JSON
- `lint/golangci_lint.bzl` (new) — `lint_golangci_lint_aspect()` factory + action
- `lint/BUILD.bazel` (modify) — add `golangci_lint_bin` alias + `bzl_library`
- `lint/multitool.lock.json` (modify) — add golangci-lint binaries
- `examples/go/` (new) — example workspace, sources, linters.bzl, lint_test
- `README.md` (modify) — add Go linter to supported-tools table

---

## Phase 0 — De-risking spike (throwaway, not committed to main)

The three risks from the spec must be proven before building the real thing. This phase produces a findings note and throwaway artifacts; nothing here ships.

### Task 0: Validate the three core assumptions

**Files:**
- Create (throwaway): `/tmp/golangci-spike/` working area
- Create: `docs/superpowers/notes/2026-06-03-golangci-spike-findings.md`

- [ ] **Step 1: Confirm `go_pkg_info_aspect` is loadable and emits the output groups**

Run from repo root:
```bash
bazel build //lint/private/...  2>/dev/null; \
echo 'load("@io_bazel_rules_go//go/tools/gopackagesdriver:aspect.bzl", "go_pkg_info_aspect", "GoPkgInfo")' > /tmp/golangci-spike/load_check.bzl
```
Then pick any Go target in the repo (find one):
```bash
bazel query 'kind("go_library", //...)' | head -3
```
Build it with the aspect and inspect output groups:
```bash
bazel build --aspects=@io_bazel_rules_go//go/tools/gopackagesdriver:aspect.bzl%go_pkg_info_aspect \
  --output_groups=go_pkg_driver_json_file,go_pkg_driver_export_file,go_pkg_driver_stdlib_json_file \
  <the-go-target>
```
Expected: builds successfully and produces `*.pkg.json`, `.x` export files, and a stdlib json file under `bazel-bin`. Record their paths.

- [ ] **Step 2: Inspect a real `.pkg.json` to confirm the schema and path placeholders**

```bash
find bazel-bin -name '*.pkg.json' | head -1 | xargs cat | python3 -m json.tool
```
Expected: object(s) with `ID`, `PkgPath`, `GoFiles`, `CompiledGoFiles`, `ExportFile`, `Imports`. Note whether paths contain `__BAZEL_EXECROOT__` / `__BAZEL_OUTPUT_BASE__` prefixes — record exactly which placeholder strings appear (the static driver must resolve these).

- [ ] **Step 3: Prove golangci-lint runs against a static driver outside Bazel**

Build the throwaway static driver (Phase 1 builds the real one; here just prove the concept):
```bash
cp /private/var/tmp/_bazel_mcramer/*/external/rules_go~/go/tools/gopackagesdriver/{flatpackage,packageregistry,json_packages_driver,driver_request,utils}.go /tmp/golangci-spike/
```
Write a minimal `main.go` in `/tmp/golangci-spike/` that:
- reads `DriverRequest` from stdin,
- globs `$GOPACKAGESDRIVER_JSON_DIR/*.pkg.json`,
- builds a `PathResolverFunc` that replaces the placeholder(s) found in Step 2 with `os.Getenv("PWD")`,
- calls `NewJSONPackagesDriver(files, prf, bazelVersion{}, request.Overlay)` and writes `GetResponse(os.Args[1:])`.

Stage the Step-1 output-group files into a dir, then run:
```bash
cd <a-checkout-of-the-package-source> && \
GOPACKAGESDRIVER=/tmp/golangci-spike/driver \
GOPACKAGESDRIVER_JSON_DIR=/tmp/golangci-spike/json \
GOFLAGS=-mod=mod golangci-lint run --output.sarif.path=/tmp/golangci-spike/out.sarif ./... ; echo "exit=$?"
```
Expected: golangci-lint loads packages via the driver (no `go list` network calls) and writes SARIF. **If it instead falls back to `go list` or errors on missing type info, record the exact error** — this is the make-or-break finding.

- [ ] **Step 4: Confirm SARIF path portability**

```bash
python3 -m json.tool /tmp/golangci-spike/out.sarif | grep -i uri | head
```
Expected: file URIs are workspace-relative. If absolute/sandbox paths appear, record this — Phase 3 must normalize them.

- [ ] **Step 5: Write findings note**

Record in `docs/superpowers/notes/2026-06-03-golangci-spike-findings.md`: the exact placeholder strings, the golangci-lint version used, the SARIF flag that worked, whether export-data-only typechecking succeeded, and any required env (`GOROOT`, `GOFLAGS`, `GOPATH`, stdlib cache dir). **These findings parameterize Phases 1 and 3.**

- [ ] **Step 6: Commit the findings note only**

```bash
git add docs/superpowers/notes/2026-06-03-golangci-spike-findings.md
git commit -m "docs: golangci-lint hermetic spike findings"
```

> **GATE:** If Step 3 cannot make golangci-lint typecheck from export-data-only deps via a static driver, STOP and revisit the design (fall back to Approach B/C in the spec) before continuing.

---

## Phase 1 — The static driver binary

### Task 1: Vendor the rules_go read-half and add a build target

**Files:**
- Create: `lint/private/gopackagesdriver_static/{flatpackage,packageregistry,json_packages_driver,driver_request,utils}.go`
- Create: `lint/private/gopackagesdriver_static/BUILD.bazel`

- [ ] **Step 1: Copy the read-half source files verbatim**

```bash
mkdir -p lint/private/gopackagesdriver_static
SRC=$(ls -d /private/var/tmp/_bazel_mcramer/*/external/rules_go~/go/tools/gopackagesdriver | head -1)
cp "$SRC"/{flatpackage,packageregistry,json_packages_driver,driver_request,utils}.go lint/private/gopackagesdriver_static/
```

- [ ] **Step 2: Add a provenance header to each copied file**

Prepend to each copied `.go` file (above the license header):
```go
// Vendored from @io_bazel_rules_go //go/tools/gopackagesdriver as of rules_go
// (version recorded in MODULE.bazel). Re-sync when bumping rules_go.
// Only the JSON read + response-assembly half is vendored; the bazel
// query/build half is intentionally omitted.
```

- [ ] **Step 3: Write the BUILD target**

Create `lint/private/gopackagesdriver_static/BUILD.bazel`:
```starlark
load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library", "go_test")

package(default_visibility = ["//visibility:public"])

go_library(
    name = "gopackagesdriver_static_lib",
    srcs = [
        "driver_request.go",
        "flatpackage.go",
        "json_packages_driver.go",
        "main.go",
        "packageregistry.go",
        "utils.go",
    ],
    importpath = "github.com/aspect-build/rules_lint/lint/private/gopackagesdriver_static",
    visibility = ["//visibility:private"],
    deps = ["@org_golang_x_tools//go/packages"],
)

go_binary(
    name = "gopackagesdriver_static",
    embed = [":gopackagesdriver_static_lib"],
    visibility = ["//visibility:public"],
)

go_test(
    name = "gopackagesdriver_static_test",
    srcs = ["main_test.go"],
    data = glob(["testdata/**"]),
    embed = [":gopackagesdriver_static_lib"],
)
```

- [ ] **Step 4: Verify the golang.org/x/tools dep is available**

```bash
grep -n "org_golang_x_tools\|golang.org/x/tools" MODULE.bazel go.mod 2>/dev/null
```
Expected: `golang.org/x/tools` is a known module (rules_go's gopackagesdriver depends on it, so it should resolve). If absent, add it via `go.mod` + `go mod tidy` and the gazelle `go_deps` extension before continuing.

- [ ] **Step 5: Commit**

```bash
git add lint/private/gopackagesdriver_static/
git commit -m "feat(go): vendor rules_go gopackagesdriver read-half"
```

### Task 2: Write the static driver `main.go` (TDD)

**Files:**
- Create: `lint/private/gopackagesdriver_static/main_test.go`
- Create: `lint/private/gopackagesdriver_static/testdata/simple.pkg.json`
- Create: `lint/private/gopackagesdriver_static/main.go`

- [ ] **Step 1: Create a fixture package JSON**

Create `lint/private/gopackagesdriver_static/testdata/simple.pkg.json` (use a real example captured in the Phase 0 findings; this is a representative shape):
```json
{
  "ID": "//foo:foo",
  "Name": "foo",
  "PkgPath": "example.com/foo",
  "GoFiles": ["__BAZEL_EXECROOT__/foo/foo.go"],
  "CompiledGoFiles": ["__BAZEL_EXECROOT__/foo/foo.go"],
  "ExportFile": "__BAZEL_EXECROOT__/bazel-out/foo.x",
  "Imports": {},
  "Standard": false
}
```

- [ ] **Step 2: Write the failing test**

Create `lint/private/gopackagesdriver_static/main_test.go`:
```go
package main

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"golang.org/x/tools/go/packages"
)

func TestRunReadsStagedJSON(t *testing.T) {
	dir := t.TempDir()
	src, _ := os.ReadFile(filepath.Join("testdata", "simple.pkg.json"))
	if err := os.WriteFile(filepath.Join(dir, "simple.pkg.json"), src, 0o644); err != nil {
		t.Fatal(err)
	}
	t.Setenv("GOPACKAGESDRIVER_JSON_DIR", dir)
	t.Setenv("GOPACKAGESDRIVER_EXECROOT", "/work")

	in := strings.NewReader(`{"Mode":1,"Tests":false}`)
	var out bytes.Buffer
	if err := run(in, &out, []string{"//foo:foo"}); err != nil {
		t.Fatalf("run: %v", err)
	}

	var resp packages.DriverResponse
	if err := json.Unmarshal(out.Bytes(), &resp); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if len(resp.Packages) != 1 || resp.Packages[0].PkgPath != "example.com/foo" {
		t.Fatalf("unexpected packages: %+v", resp.Packages)
	}
	if got := resp.Packages[0].GoFiles[0]; got != "/work/foo/foo.go" {
		t.Fatalf("placeholder not resolved: %q", got)
	}
}
```

- [ ] **Step 3: Run the test to verify it fails**

```bash
bazel test //lint/private/gopackagesdriver_static:gopackagesdriver_static_test
```
Expected: FAIL — `run` undefined (main.go not written yet).

- [ ] **Step 4: Write `main.go`**

Create `lint/private/gopackagesdriver_static/main.go`. (Adapt the placeholder name(s) to the Phase 0 findings — `__BAZEL_EXECROOT__` shown here.)
```go
// Static, hermetic GOPACKAGESDRIVER for rules_lint.
// Reads pre-staged *.pkg.json from $GOPACKAGESDRIVER_JSON_DIR and answers the
// go/packages driver protocol on stdin/stdout. It NEVER invokes bazel.
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

func pathResolver() PathResolverFunc {
	execroot := os.Getenv("GOPACKAGESDRIVER_EXECROOT")
	if execroot == "" {
		execroot, _ = os.Getwd()
	}
	return func(p string) string {
		p = strings.ReplaceAll(p, "__BAZEL_EXECROOT__", execroot)
		p = strings.ReplaceAll(p, "__BAZEL_OUTPUT_BASE__", execroot)
		p = strings.ReplaceAll(p, "__BAZEL_WORKSPACE__", execroot)
		return p
	}
}

func stagedJSONFiles() ([]string, error) {
	dir := os.Getenv("GOPACKAGESDRIVER_JSON_DIR")
	if dir == "" {
		return nil, fmt.Errorf("GOPACKAGESDRIVER_JSON_DIR not set")
	}
	return filepath.Glob(filepath.Join(dir, "*.pkg.json"))
}

func run(in io.Reader, out io.Writer, queries []string) error {
	request, err := ReadDriverRequest(in)
	if err != nil {
		return fmt.Errorf("unable to read request: %w", err)
	}
	files, err := stagedJSONFiles()
	if err != nil {
		return err
	}
	driver, err := NewJSONPackagesDriver(files, pathResolver(), bazelVersion{}, request.Overlay)
	if err != nil {
		return fmt.Errorf("unable to load JSON files: %w", err)
	}
	resp := driver.GetResponse(queries)
	data, err := json.Marshal(resp)
	if err != nil {
		return fmt.Errorf("unable to marshal response: %w", err)
	}
	_, err = out.Write(data)
	return err
}

func main() {
	if err := run(os.Stdin, os.Stdout, os.Args[1:]); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v", err)
		// go/packages falls back to `go list` on nonzero exit; force 0 so the
		// hermetic action surfaces the real error instead of a silent fallback.
		os.Exit(0)
	}
}
```

> Note: `PathResolverFunc`, `ReadDriverRequest`, `NewJSONPackagesDriver`, and `bazelVersion` come from the vendored files. If `GetResponse(queries)` returns zero packages because golangci-lint's query form (`file=…` or `./...`) does not match the `ID` labels in the JSON, read `packageregistry.go`'s `Match()` and adjust query handling per the Phase 0 findings (e.g. map `./...` → match all roots).

- [ ] **Step 5: Run the test to verify it passes**

```bash
bazel test //lint/private/gopackagesdriver_static:gopackagesdriver_static_test
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lint/private/gopackagesdriver_static/main.go lint/private/gopackagesdriver_static/main_test.go lint/private/gopackagesdriver_static/testdata/
git commit -m "feat(go): static file-reading gopackagesdriver"
```

---

## Phase 2 — Provision the golangci-lint binary

### Task 3: Add golangci-lint to multitool and alias it

**Files:**
- Modify: `lint/multitool.lock.json`
- Modify: `lint/BUILD.bazel` (add alias near the other `*_bin` aliases, ~line 12-25)

- [ ] **Step 1: Determine the version and per-platform SHA256s**

Pick the latest stable golangci-lint v2 release that supports `--output.sarif.path` (confirmed in Phase 0). For each platform, fetch and hash:
```bash
VER=2.x.y   # set to the chosen version
for tuple in linux-amd64 linux-arm64 darwin-amd64 darwin-arm64; do
  url="https://github.com/golangci/golangci-lint/releases/download/v${VER}/golangci-lint-${VER}-${tuple}.tar.gz"
  echo "$tuple $url"
  curl -sL "$url" | sha256sum
done
```
Record each URL + sha256 + the inner binary path (`golangci-lint-${VER}-${tuple}/golangci-lint`).

- [ ] **Step 2: Add the `golangci-lint` entry to the lockfile**

Insert into `lint/multitool.lock.json` (alpha-ordered among tools), filling the values from Step 1:
```json
"golangci-lint": {
  "binaries": [
    { "kind": "archive", "url": "https://github.com/golangci/golangci-lint/releases/download/v<VER>/golangci-lint-<VER>-linux-arm64.tar.gz", "file": "golangci-lint-<VER>-linux-arm64/golangci-lint", "sha256": "<sha>", "os": "linux", "cpu": "arm64" },
    { "kind": "archive", "url": "https://github.com/golangci/golangci-lint/releases/download/v<VER>/golangci-lint-<VER>-linux-amd64.tar.gz", "file": "golangci-lint-<VER>-linux-amd64/golangci-lint", "sha256": "<sha>", "os": "linux", "cpu": "x86_64" },
    { "kind": "archive", "url": "https://github.com/golangci/golangci-lint/releases/download/v<VER>/golangci-lint-<VER>-darwin-arm64.tar.gz", "file": "golangci-lint-<VER>-darwin-arm64/golangci-lint", "sha256": "<sha>", "os": "macos", "cpu": "arm64" },
    { "kind": "archive", "url": "https://github.com/golangci/golangci-lint/releases/download/v<VER>/golangci-lint-<VER>-darwin-amd64.tar.gz", "file": "golangci-lint-<VER>-darwin-amd64/golangci-lint", "sha256": "<sha>", "os": "macos", "cpu": "x86_64" }
  ]
}
```

- [ ] **Step 3: Add the alias in `lint/BUILD.bazel`**

After the `ty_bin` alias (around line 25), add:
```starlark
alias(
    name = "golangci_lint_bin",
    actual = "@multitool//tools/golangci-lint",
)
```

- [ ] **Step 4: Verify the binary resolves and runs**

```bash
bazel run @multitool//tools/golangci-lint -- version
```
Expected: prints the golangci-lint version chosen in Step 1.

- [ ] **Step 5: Commit**

```bash
git add lint/multitool.lock.json lint/BUILD.bazel
git commit -m "feat(go): provision golangci-lint via multitool"
```

---

## Phase 3 — The aspect

### Task 4: Write `lint/golangci_lint.bzl`

**Files:**
- Create: `lint/golangci_lint.bzl`

- [ ] **Step 1: Write the aspect file**

Create `lint/golangci_lint.bzl`:
```starlark
"""API for declaring a golangci-lint lint aspect that visits go_{library,binary,test} rules.

Typical usage in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:golangci_lint.bzl", "lint_golangci_lint_aspect")

golangci_lint = lint_golangci_lint_aspect(
    binary = Label("@aspect_rules_lint//lint:golangci_lint_bin"),
    config = Label("//:.golangci.yml"),
)
```
"""

load("@io_bazel_rules_go//go/tools/gopackagesdriver:aspect.bzl", "GoPkgInfo", "go_pkg_info_aspect")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OUTFILE_FORMAT", "noop_lint_action", "output_files", "patch_and_output_files", "should_visit")

_MNEMONIC = "AspectRulesLintGolangciLint"

def golangci_lint_action(ctx, executable, driver, pkg_info, config, stdout, sarif, exit_code = None, options = []):
    """Run golangci-lint hermetically against a single Go package.

    Args:
        ctx: aspect evaluation context
        executable: the golangci-lint binary
        driver: the static GOPACKAGESDRIVER binary
        pkg_info: the GoPkgInfo provider from go_pkg_info_aspect
        config: the .golangci.yml config file
        stdout: human-readable report output file
        sarif: machine-readable SARIF report output file
        exit_code: optional file capturing the exit code; if None, fail on violation
        options: extra command-line options
    """
    json_files = pkg_info.pkg_json_files
    export_files = pkg_info.export_files
    srcs = pkg_info.compiled_go_files
    stdlib = [pkg_info.stdlib_json_file] if pkg_info.stdlib_json_file else []

    inputs = depset(
        direct = [driver, config] + stdlib,
        transitive = [json_files, export_files, srcs],
    )

    # Stage all .pkg.json into a single dir the driver can glob.
    json_dir = ctx.actions.declare_directory(OUTFILE_FORMAT.format(label = ctx.label.name, mnemonic = _MNEMONIC, suffix = "json"))
    ctx.actions.run_shell(
        inputs = json_files,
        outputs = [json_dir],
        command = "mkdir -p {dir}; for f in $@; do cp \"$f\" {dir}/; done".format(dir = json_dir.path),
        arguments = [f.path for f in json_files.to_list()],
        mnemonic = _MNEMONIC + "Stage",
    )

    args = ctx.actions.args()
    args.add("run")
    args.add("--config", config.path)
    args.add("--output.sarif.path", sarif.path)
    args.add_all(options)
    args.add("./...")

    env = {
        "GOPACKAGESDRIVER": driver.path,
        "GOPACKAGESDRIVER_JSON_DIR": json_dir.path,
        "GOPACKAGESDRIVER_EXECROOT": ".",
        "GOFLAGS": "-mod=mod",
        # Keep tool caches inside the sandbox so the action stays hermetic.
        "GOCACHE": "/tmp/gocache",
        "GOLANGCI_LINT_CACHE": "/tmp/golangci-cache",
        "HOME": "/tmp",
    }

    outputs = [stdout, sarif]
    if exit_code:
        command = "{bin} \"$@\" >{stdout} 2>&1; echo $? >{ec}".format(bin = executable.path, stdout = stdout.path, ec = exit_code.path)
        outputs.append(exit_code)
    else:
        command = "{bin} \"$@\" >{stdout} 2>&1".format(bin = executable.path, stdout = stdout.path)

    ctx.actions.run_shell(
        inputs = depset(direct = [json_dir], transitive = [inputs]),
        outputs = outputs,
        command = command,
        arguments = [args],
        env = env,
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with golangci-lint",
        tools = [executable, driver],
    )

# buildifier: disable=function-docstring
def _golangci_lint_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []
    if GoPkgInfo not in target:
        return []

    pkg_info = target[GoPkgInfo]

    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    color_options = ["--color", "always"] if ctx.attr._options[LintOptionsInfo].color else []

    golangci_lint_action(
        ctx,
        ctx.executable._golangci_lint,
        ctx.executable._driver,
        pkg_info,
        ctx.file._config_file,
        outputs.human.out,
        outputs.machine.out,
        outputs.human.exit_code,
        color_options,
    )

    # machine exit code mirrors the human exit code for this single action
    if outputs.machine.exit_code:
        ctx.actions.symlink(output = outputs.machine.exit_code, target_file = outputs.human.exit_code)

    return [info]

def lint_golangci_lint_aspect(binary, config, rule_kinds = ["go_library", "go_binary", "go_test"]):
    """A factory function to create a golangci-lint linter aspect.

    Attrs:
        binary: a golangci-lint executable, typically @aspect_rules_lint//lint:golangci_lint_bin
        config: the .golangci.yml config file
        rule_kinds: which rule kinds to visit
    """
    return aspect(
        implementation = _golangci_lint_aspect_impl,
        requires = [go_pkg_info_aspect],
        attrs = {
            "_options": attr.label(default = "//lint:options", providers = [LintOptionsInfo]),
            "_golangci_lint": attr.label(default = binary, executable = True, cfg = "exec"),
            "_driver": attr.label(
                default = Label("//lint/private/gopackagesdriver_static:gopackagesdriver_static"),
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(default = config, allow_single_file = True),
            "_rule_kinds": attr.string_list(default = rule_kinds),
        },
    )
```

- [ ] **Step 2: Add the `bzl_library` to `lint/BUILD.bazel`**

After the `shellcheck` `bzl_library` block, add:
```starlark
bzl_library(
    name = "golangci_lint",
    srcs = ["golangci_lint.bzl"],
    deps = [
        "//lint/private:lint_aspect",
        "@io_bazel_rules_go//go/tools/gopackagesdriver:aspect",
    ],
)
```

- [ ] **Step 3: Buildifier + load check**

```bash
bazel run //:format -- lint/golangci_lint.bzl lint/BUILD.bazel 2>/dev/null || true
bazel query 'deps(//lint:golangci_lint)' >/dev/null && echo OK
```
Expected: `OK` (no Starlark load/syntax errors).

- [ ] **Step 4: Commit**

```bash
git add lint/golangci_lint.bzl lint/BUILD.bazel
git commit -m "feat(go): golangci-lint hermetic lint aspect"
```

> If the Phase 0 findings showed golangci-lint emits **absolute** SARIF paths, add a normalization step here: after the lint action, run a small action that rewrites the execroot prefix in the SARIF to workspace-relative, and make that the `outputs.machine.out`. Document the exact prefix to strip from the findings note.

---

## Phase 4 — Example + integration test

### Task 5: Create the `examples/go` workspace

**Files:**
- Create: `examples/go/MODULE.bazel`, `examples/go/.bazelrc`, `examples/go/.golangci.yml`, `examples/go/BUILD`, `examples/go/README.md`
- Create: `examples/go/src/clean/clean.go`, `examples/go/src/clean/BUILD`
- Create: `examples/go/src/buggy/buggy.go`, `examples/go/src/buggy/BUILD`
- Create: `examples/go/tools/lint/linters.bzl`, `examples/go/tools/lint/BUILD`

- [ ] **Step 1: Copy scaffolding from an existing example**

Use `examples/shell` as the structural template for `MODULE.bazel`/`.bazelrc`/`README.md`, then add rules_go + gazelle + the local `aspect_rules_lint` override. Inspect first:
```bash
cat examples/shell/MODULE.bazel examples/shell/.bazelrc
```

- [ ] **Step 2: Write `examples/go/.golangci.yml`**

```yaml
version: "2"
linters:
  enable:
    - staticcheck
    - govet
    - ineffassign
```

- [ ] **Step 3: Write a clean and a buggy Go source**

`examples/go/src/clean/clean.go`:
```go
package clean

// Add returns the sum of two integers.
func Add(a, b int) int {
	return a + b
}
```
`examples/go/src/buggy/buggy.go` (triggers `ineffassign`/`staticcheck`):
```go
package buggy

// Bug has an ineffectual assignment that golangci-lint must flag.
func Bug() int {
	x := 1
	x = 2
	return 3
}
```
With matching `go_library` `BUILD` files in each dir (use gazelle: `bazel run //:gazelle` after wiring it, or hand-write).

- [ ] **Step 4: Write `examples/go/tools/lint/linters.bzl`**

```starlark
"Define linter aspects"

load("@aspect_rules_lint//lint:golangci_lint.bzl", "lint_golangci_lint_aspect")
load("@aspect_rules_lint//lint:lint_test.bzl", "lint_test")

golangci_lint = lint_golangci_lint_aspect(
    binary = Label("@aspect_rules_lint//lint:golangci_lint_bin"),
    config = Label("@//:.golangci.yml"),
)

golangci_lint_test = lint_test(aspect = golangci_lint)
```

- [ ] **Step 5: Manually verify the aspect runs end-to-end**

```bash
cd examples/go && bazel build //src/... \
  --aspects=//tools/lint:linters.bzl%golangci_lint \
  --output_groups=rules_lint_machine
```
Expected: builds; the `buggy` target's SARIF report contains a finding; the `clean` target's is empty. Inspect:
```bash
find bazel-bin -name '*AspectRulesLintGolangciLint.report' -path '*buggy*' | xargs cat
```

- [ ] **Step 6: Commit**

```bash
git add examples/go/
git commit -m "feat(go): example workspace for golangci-lint aspect"
```

### Task 6: Add the lint_test asserting findings

**Files:**
- Create: `examples/go/test/BUILD`
- Create: `examples/go/test/lint_test.bats` (mirror `examples/shell/test/lint_test.bats`)

- [ ] **Step 1: Inspect the shell example's test for the pattern**

```bash
cat examples/shell/test/lint_test.bats examples/shell/test/BUILD
```

- [ ] **Step 2: Write a lint_test target on the buggy package**

In `examples/go/test/BUILD`, instantiate `golangci_lint_test` against `//src/buggy` and assert a nonzero/finding result, following the shell example's assertions exactly.

- [ ] **Step 3: Run the test**

```bash
cd examples/go && bazel test //test:all
```
Expected: PASS — the test confirms golangci-lint flags the buggy package and passes the clean one.

- [ ] **Step 4: Verify cache reuse (the explicit goal)**

```bash
cd examples/go && bazel build //src/... --aspects=//tools/lint:linters.bzl%golangci_lint --output_groups=rules_lint_machine
# touch only the buggy package; the clean package's lint action must be a cache hit
touch src/buggy/buggy.go
bazel build //src/... --aspects=//tools/lint:linters.bzl%golangci_lint --output_groups=rules_lint_machine 2>&1 | grep -i "processes\|cached"
```
Expected: the second build re-runs only the buggy package's golangci-lint action; the clean package is cached.

- [ ] **Step 5: Commit**

```bash
git add examples/go/test/
git commit -m "test(go): lint_test for golangci-lint example"
```

---

## Phase 5 — Documentation

### Task 7: Add Go linter to the README supported-tools table

**Files:**
- Modify: `README.md` (the supported-tools table, the `| Go ... |` row)

- [ ] **Step 1: Update the Go row**

In `README.md`, change the Go table row to add golangci-lint under Linter(s):
```
| Go                     | [gofmt] or [gofumpt]      | [golangci-lint]                                         |
```
And add the link reference near the other link definitions:
```
[golangci-lint]: https://golangci-lint.run/
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add golangci-lint to supported tools"
```

> Docsite (`~/Code/Aspect/docs/docs`) update is handled separately per repo convention — prompt before editing `docs.json`.

---

## Self-Review notes (addressed)

- **Spec coverage:** static driver (Tasks 1–2), provisioning (Task 3), aspect with `requires=[go_pkg_info_aspect]` (Task 4), native SARIF (Task 4), example+test (Tasks 5–6), cache reuse validated (Task 6 Step 4), README (Task 7). The three spec risks are gated in Phase 0.
- **Cache reuse:** per-package granularity (one action per target), export-data inputs (`export_files` depset, not source), sandbox-local `GOCACHE`/`GOLANGCI_LINT_CACHE`, and a portability check for SARIF paths (Phase 0 Step 4 + Task 4 fallback note).
- **Type consistency:** `pkg_info.pkg_json_files`, `.export_files`, `.compiled_go_files`, `.stdlib_json_file` match the `GoPkgInfo` provider fields verified in rules_go's `aspect.bzl`. Driver symbols (`ReadDriverRequest`, `NewJSONPackagesDriver`, `PathResolverFunc`, `bazelVersion`) come from the vendored files.
- **Known soft spots flagged inline:** query-form matching in the driver (Task 2 Step 4 note) and SARIF path normalization (Task 4 note) are the two items most likely to need adjustment from Phase 0 findings.
