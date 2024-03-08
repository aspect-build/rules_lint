"""API for declaring a golangci-lint lint aspect that visits go_library, go_test, and go_binary rules.

```
load("@aspect_rules_lint//lint:golangci-lint.bzl", "golangci_lint_aspect")

golangci_lint = golangci_lint_aspect(
    binary = "@@//tools/lint:golangci_lint",
    config = "@@//:.golangci.yaml",
)
```
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@io_bazel_rules_go//go:def.bzl", "go_context")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "filter_srcs", "report_file")

_MNEMONIC = "golangcilint"

def golangci_lint_action(ctx, executable, srcs, config, report, use_exit_code = False):
    """Run golangci-lint as an action under Bazel.

    Based on https://github.com/golangci/golangci-lint

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the golangci-lint program
        srcs: golang files to be linted
        config: label of the .golangci.yaml file
        report: output file to generate
        use_exit_code: whether to fail the build when a lint violation is reported
    """

    # golangci-lint calls out to Go, so we need the go context
    go = go_context(ctx)
    inputs = srcs + [config] + go.sdk_files
    args = ctx.actions.args()
    args.add_all(srcs)

    command = """#!/usr/bin/env bash
        export GOROOT=$(cd "$(dirname {go_tool})/.."; pwd)
        export GOPATH=$GOROOT
        export GOCACHE="$(mktemp -d)"
        export PATH="$GOPATH/bin:$PATH"
        GOLANGCI_LINT_CACHE=$(pwd)/.cache {golangci_lint} run --config={config} $@"""

    if use_exit_code:
        command += " && touch {report}"
    else:
        command += " >{report} || true"

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [report],
        command = command.format(
            golangci_lint = executable.path,
            report = report.path,
            config = config.path,
            go_tool = ctx.toolchains["@io_bazel_rules_go//go:toolchain"].sdk.go.path,
        ),
        env = go.env,
        arguments = [args],
        mnemonic = _MNEMONIC,
        tools = [executable],
    )

# buildifier: disable=function-docstring
def _golangci_lint_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["go_binary", "go_library", "go_test"]:
        return []

    report, info = report_file(_MNEMONIC, target, ctx)

    srcs = filter_srcs(ctx.rule)
    if not srcs:
        return []

    golangci_lint_action(ctx, ctx.executable._golangci_lint, srcs, ctx.file._config_file, report, ctx.attr._options[LintOptionsInfo].fail_on_violation)
    return [info]

def golangci_lint_aspect(binary, config):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a golangci-lint executable.
        config: the .golangci.yaml file
    """
    return aspect(
        implementation = _golangci_lint_aspect_impl,
        attrs = {
            "_options": attr.label(
                default = "//lint:fail_on_violation",
                providers = [LintOptionsInfo],
            ),
            "_golangci_lint": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_single_file = True,
            ),
        },
        toolchains = ["@io_bazel_rules_go//go:toolchain"],
    )

def fetch_golangci_lint(version = "1.55.2"):
    """Naive macro that fetches a specific version of the golangci-lint from GitHub releases, for commonly-used platforms

    Args:
        version: must be the default value. In the future this could be honored when we support multiple versions.
    """
    if version != "1.55.2":
        fail("Only a single version of golangci-lint is currently mirrored. Please file an issue if you need a different version.")
    http_archive(
        name = "golangci_lint_linux_x86_64",
        build_file_content = "exports_files([\"golangci-lint\"])",
        strip_prefix = "golangci-lint-{}-linux-amd64".format(version),
        sha256 = "ca21c961a33be3bc15e4292dc40c98c8dcc5463a7b6768a3afc123761630c09c",
        urls = ["https://github.com/golangci/golangci-lint/releases/download/v{0}/golangci-lint-{0}-linux-amd64.tar.gz".format(version)],
    )
    http_archive(
        name = "golangci_lint_linux_aarch64",
        build_file_content = "exports_files([\"golangci-lint\"])",
        strip_prefix = "golangci-lint-{}-linux-arm64".format(version),
        sha256 = "8eb0cee9b1dbf0eaa49871798c7f8a5b35f2960c52d776a5f31eb7d886b92746",
        urls = ["https://github.com/golangci/golangci-lint/releases/download/v{0}/golangci-lint-{0}-linux-arm64.tar.gz".format(version)],
    )
    http_archive(
        name = "golangci_lint_macos_x86_64",
        build_file_content = "exports_files([\"golangci-lint\"])",
        strip_prefix = "golangci-lint-{}-darwin-amd64".format(version),
        sha256 = "632e96e6d5294fbbe7b2c410a49c8fa01c60712a0af85a567de85bcc1623ea21",
        urls = ["https://github.com/golangci/golangci-lint/releases/download/v{0}/golangci-lint-{0}-darwin-amd64.tar.gz".format(version)],
    )
    http_archive(
        name = "golangci_lint_macos_aarch64",
        build_file_content = "exports_files([\"golangci-lint\"])",
        strip_prefix = "golangci-lint-{}-darwin-arm64".format(version),
        sha256 = "234463f059249f82045824afdcdd5db5682d0593052f58f6a3039a0a1c3899f6",
        urls = ["https://github.com/golangci/golangci-lint/releases/download/v{0}/golangci-lint-{0}-darwin-arm64.tar.gz".format(version)],
    )
