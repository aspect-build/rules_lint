# Formatting

## Installation

Create a BUILD file that declares the formatter binary, typically at `tools/BUILD.bazel`

Each formatter should be installed in your repository, see our `example/tools/BUILD` file.
A formatter is just an executable target.

Then register them on the `formatters` attribute, for example:

```starlark
load("@aspect_rules_lint//format:defs.bzl", "multi_formatter_binary")

multi_formatter_binary(
    name = "format",
    # register languages, e.g.
    # python = "//:ruff",
)
```

Finally, we recommend an alias in the root BUILD file:

```starlark
alias(
    name = "format",
    actual = "//tools:format",
)
```

## Usage

### One-time re-format all files

Assuming you installed with the typical layout:

`bazel run :format`

> Note that mass-reformatting can be disruptive in an active repo.
> You may want to instruct developers with in-flight changes to reformat their branches as well, to avoid merge conflicts.
> Also consider adding your re-format commit to the
> [`.git-blame-ignore-revs` file](https://docs.github.com/en/repositories/working-with-files/using-files/viewing-a-file#ignore-commits-in-the-blame-view)
> to avoid polluting the blame layer.

### Re-format specific file(s)

`bazel run format some/file.md other/file.json`

### Install as a pre-commit hook

If you use [pre-commit.com](https://pre-commit.com/), add this in your `.pre-commit-config.yaml`:

```yaml
- repo: local
  hooks:
    - id: aspect_rules_lint
      name: Format
      language: system
      entry: bazel run //:format
      files: .*
```

> Note that pre-commit is silent while Bazel is fetching the tooling, which can make it appear hung on the first run.
> There is no way to avoid this; see https://github.com/pre-commit/pre-commit/issues/1003

If you don't use pre-commit, you can just wire directly into the git hook, however
this option will always run the formatter over all files, not just changed files.

```bash
$ echo "bazel run //:format -- --mode check" >> .git/hooks/pre-commit
$ chmod u+x .git/hooks/pre-commit
```

### Check that files are already formatted

This will exit non-zero if formatting is needed. You would typically run the check mode on CI.

`bazel run //:format -- --mode check`
