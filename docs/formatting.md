# Formatting

## Installation

Create a BUILD file that declares the formatter binary, typically at `tools/format/BUILD.bazel`

This file contains a `format_multirun` rule. To use the tools supplied by default in rules_lint,
just make a simple call to it like so:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

format_multirun(name = "format")
```

For more details, see the `format_multirun` [API documentation](./format.md) and
the `example/tools/format/BUILD.bazel` file.

Finally, we recommend an alias in the root BUILD file, so that developers can just type `bazel run format`:

```starlark
alias(
    name = "format",
    actual = "//tools/format",
)
```

### Choosing formatter tools

Each formatter should be installed by Bazel. A formatter is just an executable target.

`rules_lint` provides some default tools at specific versions using
[rules_multitool](https://github.com/theoremlp/rules_multitool).
You may fetch alternate tools or versions instead.

To register the tools you fetch, supply them as values for that language attribute.

For example:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

format_multirun(
    name = "format",
    python = ":ruff",
)
```

File discovery for each language is based on file extension and shebang-based discovery is currently limited to shell.

### Terraform formatter

When formatting Terraform sources we recommend using the binary published with
[`rules_tf`](https://github.com/yanndegat/rules_tf) so the version is managed by Bazel.
Under bzlmod you can add the module and register the toolchains so the built-in `terraform`
language attribute resolves to the correct executable:

```starlark
bazel_dep(name = "rules_tf", version = "0.0.10")

tf = use_extension("@rules_tf//tf:extensions.bzl", "tf_repositories")
tf.download(
    version = "1.9.8",
    mirror = {"aws": "hashicorp/aws:5.90.0"},
)
use_repo(tf, "tf_toolchains")
register_toolchains("@tf_toolchains//:all")
```

WORKSPACE users can continue to use the multitool-provided binary without any additional setup.
If you need the same version pin in WORKSPACE mode, download `rules_tf` via
`rules_lint_dependencies()` and register the toolchains with the helper provided in this repo:

```starlark
load("@aspect_rules_lint//lint:tf_toolchains_workspace.bzl", "rules_lint_setup_tf_toolchains")

rules_lint_setup_tf_toolchains(
    version = "1.9.8",
    mirror = {"aws": "hashicorp/aws:5.90.0"},
)
```

The helper detects the host platform automatically using Bazel's host platform constraints.

## Usage

### Configuring formatters

Since the `format` target is a `bazel run` command, it already runs in the working directory alongside the sources.
Therefore the configuration instructions for the formatting tool should work as-is.
Whatever configuration files the formatter normally discovers will be used under Bazel as well.

As an example, if you want to change the indent level for Shell formatting, you can follow the
[instructions for shfmt](https://github.com/mvdan/sh/blob/master/cmd/shfmt/shfmt.1.scd#examples) and create a `.editorconfig` file: 

```
[[shell]]
indent_style = space
indent_size = 4
```

### Custom formatter arguments

You can override the default command-line arguments passed to formatters by specifying custom arguments for each language and mode:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

format_multirun(
    name = "format",
    kotlin = ":ktfmt",
    kotlin_fix_args = ["--google-style"],
    kotlin_check_args = ["--google-style", "--set-exit-if-changed", "--dry-run"],
    java = ":java-format",
    java_fix_args = ["--aosp", "--replace"],
    python = ":ruff",
    python_check_args = ["format", "--check", "--diff"],
)
```

The custom argument attributes follow the pattern `{language}_{mode}_args`:
- `{language}_fix_args`: Arguments used when running `bazel run //:format` (fix mode)
- `{language}_check_args`: Arguments used for both `bazel run //:format.check` (check mode) and `format_test` (test mode)

When custom arguments are specified, they completely replace the default arguments for that mode.
If not specified, the built-in defaults for each formatter are used.

### One-time re-format all files

Assuming you installed with the typical layout:

`bazel run //:format`

> Note that mass-reformatting can be disruptive in an active repo.
> You may want to instruct developers with in-flight changes to reformat their branches as well, to avoid merge conflicts.
> Also consider adding your re-format commit to the
> [`.git-blame-ignore-revs` file](https://docs.github.com/en/repositories/working-with-files/using-files/viewing-a-file#ignore-commits-in-the-blame-view)
> to avoid polluting the blame layer.

### Re-format specific file(s)

`bazel run //:format some/file.md other/file.json`

### Ignoring files explicitly

Commonly, the underlying formatters that rules_lint invokes provide their own methods of excluding files (.prettierignore for example).

At times when that is not the case, rules_lint provides a means to exclude files from being formatted by using attributes specified via [`.gitattributes` files](https://git-scm.com/docs/gitattributes).

If any of following attributes are set or have a value of `true` on a file it will be excluded:

- `gitlab-generated=true`
- `linguist-generated=true`
- `rules-lint-ignored=true`

Note that the first two attributes also have the side effect of preventing the generated files from being shown to code reviewers,
and from being included in language stats, for GitLab and GitHub respectively. See [GitHub docs](https://docs.github.com/en/repositories/working-with-files/managing-files/customizing-how-changed-files-appear-on-github).

### Install as a pre-commit hook

#### Using the pre-commit tool
Developers could choose to install [pre-commit.com](https://pre-commit.com/) (note that it has a Python system dependency).

In this case you can add this in your `.pre-commit-config.yaml`:

```yaml
- repo: local
  hooks:
    - id: aspect_rules_lint
      name: Format
      language: system
      entry: bazel run //:format
      files: .*
```

> Note that pre-commit is silent while Bazel is fetching the tools, which can make it appear hung on the first run.
> There is no way to avoid this; see https://github.com/pre-commit/pre-commit/issues/1003

#### Using a locally-defined hook

If you don't use pre-commit, you can just wire directly into the git hook.
Here is a nice pattern to ensure your co-workers install the hook, and also to only format the added or modified files:

1. If you don't have a workspace status script, which Bazel runs on every execution, then create `githooks/check-config.sh`, make it executable, and register in `.bazelrc` with `common --workspace_status_command=githooks/check-config.sh` (note that a release build likely overrides the `workspace_status_command` to support stamping)

2. Use a snippet like the following in that script:

```bash
#!/usr/bin/env bash
inside_work_tree=$(git rev-parse --is-inside-work-tree 2>/dev/null)

# Encourage developers to setup githooks
IFS='' read -r -d '' GITHOOKS_MSG <<"EOF"
    cat <<EOF
  It looks like the git config option core.hooksPath is not set.
  This repository uses hooks stored in githooks/ to run tools such as formatters.
  You can disable this warning by running:

    echo "common --workspace_status_command=" >> ~/.bazelrc

  To set up the hooks, please run:

    git config core.hooksPath githooks
EOF

if [ "${inside_work_tree}" = "true" ] && [ "$EUID" -ne 0 ] && [ -z "$(git config core.hooksPath)" ]; then
    echo >&2 "${GITHOOKS_MSG}"
fi
```

3. Finally, create the `githooks/pre-commit` file, make it executable and add a snippet like:

```bash
#!/usr/bin/env bash
git diff --cached --diff-filter=AM --name-only -z | xargs --null --no-run-if-empty bazel run //:format --
if ! git diff --quiet; then
  echo "❌ Some files were modified by the pre-commit hook."
  echo "Please review and stage the changes before committing again."
  git diff --stat
  exit 1
fi
```

### Check that files are already formatted

We recommend using [Aspect Workflows] to hook up the CI check to notify developers of formatting changes,
and supply a patch file that can be locally applied.

![format on CI](./format-ci-demo.png)

To set this up manually, there are two supported methods:

#### 1: `run` target

This will exit non-zero if formatting is needed. You would typically run the check mode on CI.

`bazel run //tools/format:format.check`

#### 2: `test` target

Normally Bazel tests should be hermetic, declaring their inputs, and therefore have cacheable results.

This is possible with `format_test` and a list of `srcs`.
Note that developers may not remember to add `format_test` for their new source files, so this is quite brittle,
unless you also use a tool like [Gazelle] to automatically update BUILD files.

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_test")

format_test(
    name = "format_test",
    # register languages, e.g.
    # python = "//:ruff",
    srcs = ["my_code.go"],
)
```

Alternatively, you can give up on Bazel's hermeticity, and
follow a similar pattern as [buildifier_test](https://github.com/bazelbuild/buildtools/pull/1092)
which creates an intentionally non-hermetic, and not cacheable target.

This will *always* run the formatters over all files under `bazel test`, so this technique is only appropriate
when the formatters are fast enough, and/or the number of files in the repository are few enough.
To acknowledge this fact, this mode requires an additional opt-in attribute, `no_sandbox`.

```starlark
load("@aspect_rules_lint//format:defs.bzl", "format_test")

format_test(
    name = "format_test",
    # register languages, e.g.
    # python = "//:ruff",
    no_sandbox = True,
    workspace = "//:WORKSPACE.bazel",
)
```

Then run `bazel test //tools/format/...` to check that all files are formatted.

[Gazelle]: https://github.com/bazelbuild/bazel-gazelle
[Aspect Workflows]: https://docs.aspect.build/workflows
[Aspect CLI]: https://docs.aspect.build/cli
