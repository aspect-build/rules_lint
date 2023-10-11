# Run linters under Bazel (EXPERIMENTAL)

> It is currently EXPERIMENTAL and pre-release. No support is promised.
> There may be breaking changes, or we may archive and abandon the repository.

This ruleset integrates linting as a first-class concept under Bazel.

Features:

- **No changes needed to rulesets**. Works with the Bazel rules you already use.
- **No changes needed to BUILD files**. You don't need to add lint wrapper macros, and lint doesn't appear in `bazel query` output.
  Instead, users can lint their existing `*_library` targets.
- Lints can be **presented in various ways**:
  - a hard failure, like it would with a `lint_test` rule that fails the build
  - as a warning, using whatever reporting method you prefer
  - or even as bot code review comments (e.g. with [reviewdog])

How developers use it:

1. (preferred) This ruleset provides an Aspect CLI plugin,
  so it can register the missing 'lint' command and users just type `bazel lint //path/to:targets`.
2. Run with vanilla Bazel, by placing a couple commands in a shell script, Makefile, or similar wrapper.

This project is inspired by the design for [Tricorder].
This is how Googlers get their static analysis results in code review (Critique).
https://github.com/google/shipshape is an old, abandoned attempt to open-source Tricorder.

Note: we believe that Formatting is **NOT** Linting.
We have a separate project for formatting, see <https://github.com/aspect-build/bazel-super-formatter#design>

[aspect cli]: https://docs.aspect.build/v/cli
[tricorder]: https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/43322.pdf
[reviewdog]: https://github.com/reviewdog/reviewdog

## Adding a linter

TODO: step-by-step instructions to add a linter in this repo, and maybe how to add one in your repo.

## Installation

Follow instructions from the release you wish to use:
<https://github.com/aspect-build/rules_lint/releases>
