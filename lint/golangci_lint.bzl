"""API for declaring a golangci-lint lint aspect that visits go_{library,binary,test} rules.

Typical usage in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:golangci_lint.bzl", "lint_golangci_lint_aspect")

golangci_lint = lint_golangci_lint_aspect(
    binary = Label("@aspect_rules_lint//lint:golangci_lint_bin"),
    config = Label("//:.golangci.yml"),
)
```

This aspect is hermetic, per-package, and remote-cache friendly. It reuses
rules_go's `go_pkg_info_aspect` to obtain each package's pre-computed metadata
(`.pkg.json`), transitive export data (`.x`), and stdlib archives, then runs the
real golangci-lint binary against a static, file-reading `GOPACKAGESDRIVER`
(`//lint/private/gopackagesdriver_static`). No bazel-in-bazel, no network, no
shared module cache. See `docs/superpowers/notes/2026-06-03-golangci-spike-findings.md`.
"""

load("@io_bazel_rules_go//go/private:providers.bzl", "GoStdLib")
load("@io_bazel_rules_go//go/tools/gopackagesdriver:aspect.bzl", "GoPkgInfo", "go_pkg_info_aspect")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OUTFILE_FORMAT", "output_files", "should_visit")

_MNEMONIC = "AspectRulesLintGolangciLint"

# The rules_go Go toolchain type, used to reach the GoSDK (for GOROOT) at lint
# time. Reached via ctx.toolchains[...] because the aspect declares it in
# `toolchains` below.
_GO_TOOLCHAIN = "@io_bazel_rules_go//go:toolchain"

def golangci_lint_action(ctx, executable, driver, pkg_info, sdk, stdlib, config, stdout, sarif, exit_code = None, options = []):
    """Run golangci-lint hermetically against a single Go package.

    Args:
        ctx: aspect evaluation context
        executable: the golangci-lint binary
        driver: the static GOPACKAGESDRIVER binary
        pkg_info: the GoPkgInfo provider from go_pkg_info_aspect
        sdk: the rules_go GoSDK provider (used to derive GOROOT and the go binary)
        stdlib: the rules_go GoStdLib provider (precompiled stdlib .a archives)
        config: the .golangci.yml config file
        stdout: human-readable report output file
        sarif: machine-readable (raw, pre-normalization) SARIF report output file
        exit_code: optional file capturing the exit code; if None, fail on violation
        options: extra command-line options

    Returns:
        nothing; declares the lint action.
    """
    json_files = pkg_info.pkg_json_files
    export_files = pkg_info.export_files
    srcs = pkg_info.compiled_go_files
    stdlib_json = [pkg_info.stdlib_json_file] if pkg_info.stdlib_json_file else []

    # rules_go builds the stdlib into a single "pkg" tree exposed via
    # GoStdLib.libs, laid out as pkg/<goos>_<goarch>/<importpath>.a. The static
    # driver injects each as the ExportFile for the corresponding Standard
    # package (spike finding #1). NOTE: the GoSDK's own `libs` is empty for
    # modern (>=1.20) SDKs, which is why we read the BUILT stdlib here instead.
    stdlib_libs_list = stdlib.libs.to_list()

    # Stage all .pkg.json (target + transitive deps + stdlib) into a single dir
    # the driver can glob via GOPACKAGESDRIVER_JSON_DIR. The stdlib_json_file
    # (~294 stdlib packages in one file) MUST be included: without it the driver's
    # registry has no stdlib packages, so it can neither inject their ExportFile
    # nor resolve dependencies' stdlib imports (e.g. encoding/xml, fmt).
    stage_inputs = depset(direct = stdlib_json, transitive = [json_files])
    json_dir = ctx.actions.declare_directory(OUTFILE_FORMAT.format(label = ctx.label.name, mnemonic = _MNEMONIC, suffix = "pkgjson.d"))
    stage_args = ctx.actions.args()
    stage_args.add(json_dir.path)
    stage_args.add_all(stage_inputs)
    ctx.actions.run_shell(
        inputs = stage_inputs,
        outputs = [json_dir],
        command = 'dir="$1"; shift; mkdir -p "$dir"; for f in "$@"; do dest="$dir/$(basename "$f")"; cp -f "$f" "$dest"; chmod u+w "$dest"; done',
        arguments = [stage_args],
        mnemonic = _MNEMONIC + "Stage",
        progress_message = "Staging Go package metadata for %{label}",
    )

    # GOROOT is the directory containing the SDK root_file. golangci-lint shells
    # out to `go env` for its build context, so the go binary must also be on
    # PATH (at $GOROOT/bin). Dependency type info still comes from the injected
    # stdlib ExportFiles, not from compiling against GOROOT.
    goroot = sdk.root_file.dirname

    args = ctx.actions.args()
    args.add("run")
    args.add("--config", config.path)
    args.add("--output.sarif.path", sarif.path)
    args.add_all(options)
    args.add("./...")

    env = {
        "GOPACKAGESDRIVER": driver.path,
        "GOPACKAGESDRIVER_JSON_DIR": json_dir.path,
        "GOPACKAGESDRIVER_ROOTS": str(ctx.label),
        # The bazel placeholders in the staged JSON resolve against the sandbox
        # execroot, which the action runs in (cwd == execroot == ".").
        "GOPACKAGESDRIVER_EXECROOT": ".",
        "GOPACKAGESDRIVER_WORKSPACE": ".",
        "GOPACKAGESDRIVER_OUTPUT_BASE": ".",
        "GOFLAGS": "-mod=mod",
        "GOPROXY": "off",
        # Dependencies are loaded as export data only (the driver strips their
        # source). x/tools' gcimporter has a data race when decoding export data
        # concurrently; serialize the loader to avoid "concurrent map read and
        # map write" crashes. Per-package lint actions are small, so the
        # single-threaded cost is negligible.
        "GOMAXPROCS": "1",
        # Keep tool caches inside the sandbox so the action stays hermetic and
        # machine-independent (no shared GOCACHE / module cache).
        "GOCACHE": "/tmp/rules_lint_gocache",
        "GOLANGCI_LINT_CACHE": "/tmp/rules_lint_golangci_cache",
        "HOME": "/tmp",
    }

    # GOPACKAGESDRIVER_STDLIB_PKG_DIR points at the dir that *contains* the
    # <goos>_<goarch>/ subtree of precompiled .a files. GoStdLib.libs is a single
    # tree artifact: the "pkg" directory itself (.../stdlib_/pkg). The driver
    # appends "<goos>_<goarch>/<importpath>.a" to it.
    if stdlib_libs_list:
        env["GOPACKAGESDRIVER_STDLIB_PKG_DIR"] = stdlib_libs_list[0].path

    inputs = depset(
        direct = [driver, config, sdk.root_file] + stdlib_json + stdlib_libs_list,
        transitive = [json_files, export_files, srcs, pkg_info.stdlib_cache_dir, sdk.srcs, sdk.headers, sdk.tools, sdk.libs, depset([sdk.go])],
    )

    outputs = [stdout, sarif]

    # GOROOT/PATH must be absolute: Go refuses to exec a `go` binary found via a
    # relative path ("cannot run executable found relative to current
    # directory"). The action runs at the execroot, so prefix with $PWD at
    # runtime. golangci-lint shells out to `go env` for its build context.
    goroot_prologue = 'export GOROOT="$PWD/' + goroot + '"; export PATH="$GOROOT/bin:$PATH"; '

    # $1 is the golangci-lint binary path; "$@" (after shift) are its args. We
    # avoid str.format here because the shell expansions $@ / $? collide with
    # format's {} fields.
    if exit_code:
        # golangci-lint exits 1 when issues are found; capture rather than fail.
        command = goroot_prologue + 'bin="$1"; shift; "$bin" "$@" >' + stdout.path + ' 2>&1; echo $? >' + exit_code.path
        outputs.append(exit_code)
    else:
        command = goroot_prologue + 'bin="$1"; shift; "$bin" "$@" >' + stdout.path + ' 2>&1'

    run_args = ctx.actions.args()
    run_args.add(executable.path)

    ctx.actions.run_shell(
        inputs = depset(direct = [json_dir], transitive = [inputs]),
        outputs = outputs,
        command = command,
        arguments = [run_args, args],
        env = env,
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with golangci-lint",
        tools = [executable, driver],
    )

def _normalize_sarif_action(ctx, raw_sarif, normalized_sarif):
    """Rewrite golangci-lint SARIF result URIs to workspace-relative paths.

    golangci-lint emits `artifactLocation.uri` values that are relative to the
    linter's CWD (the bazel execroot), reaching first-party sources via deep
    `../` traversal and external-dep sources via the bazel cache (spike finding
    #3). Neither form is portable across machines, which defeats remote-cache
    sharing of the SARIF output.

    This action canonicalizes each `uri`:
      * The workspace prefix (resolved from __BAZEL_WORKSPACE__, which at runtime
        is the execroot the linter ran in) is stripped so first-party files
        become workspace-relative (e.g. `tools/sarif/sarif.go`).
      * URIs that still escape the workspace (leading `../`, i.e. external-dep
        sources living in the bazel cache) are left with an `external/` marker
        prefix collapsed from the `../`, so they are clearly non-local and never
        masquerade as a first-party path.

    Args:
        ctx: aspect evaluation context
        raw_sarif: the SARIF file produced by golangci-lint
        normalized_sarif: the rewritten, workspace-relative SARIF (machine output)
    """
    ctx.actions.run_shell(
        inputs = [raw_sarif],
        outputs = [normalized_sarif],
        command = _SARIF_NORMALIZE_SCRIPT.format(
            src = raw_sarif.path,
            dst = normalized_sarif.path,
        ),
        mnemonic = _MNEMONIC + "Sarif",
        progress_message = "Normalizing golangci-lint SARIF URIs for %{label}",
    )

# A small python3 post-processor. We collapse any leading "../" sequences: a URI
# that does not escape its anchor is already workspace-relative; one that does
# (external deps in the cache) is re-rooted under "external/" so it is clearly
# marked non-local. Empty input (no findings / empty file) yields a minimal
# valid empty SARIF document.
_SARIF_NORMALIZE_SCRIPT = """\
python3 - "{src}" "{dst}" <<'PY'
import json, os, sys
src, dst = sys.argv[1], sys.argv[2]
EMPTY = {{"version": "2.1.0", "$schema": "https://json.schemastore.org/sarif-2.1.0.json", "runs": []}}
try:
    with open(src) as f:
        raw = f.read().strip()
    doc = json.loads(raw) if raw else EMPTY
except (ValueError, OSError):
    doc = EMPTY

def normalize_uri(uri):
    if not uri:
        return uri
    # Drop a file:// scheme if present.
    if uri.startswith("file://"):
        uri = uri[len("file://"):]
    # golangci-lint emits paths relative to its working directory, which under
    # Bazel sandboxing resolves through a long "../" climb into the absolute
    # sandbox execroot (e.g. "../../../<abs>/execroot/_main/tools/sarif/sarif.go").
    # The portable, workspace-relative path is whatever follows
    # "execroot/<repo>/": for the main repo that yields "tools/sarif/sarif.go",
    # and for dependencies "external/...", which reads as clearly non-local.
    marker = "/execroot/"
    i = uri.find(marker)
    if i != -1:
        rest = uri[i + len(marker):]          # e.g. "_main/tools/sarif/sarif.go"
        j = rest.find("/")                    # drop the leading "<repo>/" segment
        return rest[j + 1:] if j != -1 else rest
    # Already-relative or non-Bazel path: just drop "./" and "../" noise.
    parts = [p for p in uri.split("/") if p not in ("", ".", "..")]
    return "/".join(parts)

for run in doc.get("runs", []):
    for result in run.get("results", []):
        for loc in result.get("locations", []):
            phys = loc.get("physicalLocation", {{}})
            art = phys.get("artifactLocation")
            if art and "uri" in art:
                art["uri"] = normalize_uri(art["uri"])

with open(dst, "w") as f:
    json.dump(doc, f, indent=2)
PY
"""

# buildifier: disable=function-docstring
def _golangci_lint_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []
    if GoPkgInfo not in target:
        return []

    pkg_info = target[GoPkgInfo]
    sdk = ctx.toolchains[_GO_TOOLCHAIN].sdk
    stdlib = ctx.attr._go_stdlib[GoStdLib]

    options = ctx.attr._options[LintOptionsInfo]
    outputs, info = output_files(_MNEMONIC, target, ctx)

    extra_options = []
    if options.color:
        extra_options.extend(["--color", "always"])

    # NOTE: golangci-lint's --fix modifies sources in place rather than emitting
    # a unified diff (unlike shellcheck's --format diff). Producing a hermetic
    # patch would require staging writable source copies and diffing; patch/fix
    # mode is intentionally not wired here. See the report / README.

    # golangci-lint writes SARIF to a path we control. Capture the raw SARIF in
    # a temp file and normalize it into the machine output.
    raw_sarif = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_sarif"))

    golangci_lint_action(
        ctx,
        ctx.executable._golangci_lint,
        ctx.executable._driver,
        pkg_info,
        sdk,
        stdlib,
        ctx.file._config_file,
        outputs.human.out,
        raw_sarif,
        outputs.human.exit_code,
        extra_options,
    )

    _normalize_sarif_action(ctx, raw_sarif, outputs.machine.out)

    # The machine exit code mirrors the human exit code for this single action.
    if outputs.machine.exit_code:
        ctx.actions.symlink(output = outputs.machine.exit_code, target_file = outputs.human.exit_code)

    return [info]

def lint_golangci_lint_aspect(binary, config, rule_kinds = ["go_library", "go_binary", "go_test"]):
    """A factory function to create a golangci-lint linter aspect.

    Attrs:
        binary: a golangci-lint executable, typically `@aspect_rules_lint//lint:golangci_lint_bin`.
        config: the `.golangci.yml` config file.
        rule_kinds: which rule kinds to visit; defaults to go_library, go_binary, go_test.

    Returns:
        an aspect definition.
    """
    return aspect(
        implementation = _golangci_lint_aspect_impl,
        # Reuse rules_go's per-package metadata (pkg.json, .x, stdlib).
        requires = [go_pkg_info_aspect],
        attrs = {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_golangci_lint": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_driver": attr.label(
                default = Label("//lint/private/gopackagesdriver_static:gopackagesdriver_static"),
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_single_file = True,
            ),
            "_go_stdlib": attr.label(
                default = "@io_bazel_rules_go//:stdlib",
                providers = [GoStdLib],
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
        toolchains = [_GO_TOOLCHAIN],
    )
