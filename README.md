# Run linters under Bazel (EXPERIMENTAL)

> It is currently EXPERIMENTAL and pre-release. No support is promised.
> There may be breaking changes, or we may archive and abandon the repository.

This ruleset integrates linting as a first-class concept under Bazel.

Design goals:

- Linting rules don't need to be added to BUILD files or macros, and they do not appear in `bazel query` output. Instead, users should be able to lint existing `*_library`-style targets.
- Lints can be presented in various ways: as a hard failure, as a warning, or even as bot code review comments (e.g. with [reviewdog])
- Work for all languages/frameworks.
- Make it easy to add support for new linters.
- Developer ergonomics:
  - make it _possible_ to run with vanilla Bazel, which has no `lint`  
    command, using some awkward command-lines. Typical users will want to
    put these in a shell script, Makefile, or similar wrapper.
  - Using [Aspect CLI] you simply run `aspect lint`

This project is inspired by the design for [Tricorder].
This is how Googlers get their static analysis results in code review (Critique).
https://github.com/google/shipshape is an old, abandoned attempt to open-source Tricorder.

Note: we believe that Formatting is **NOT** Linting. We have a separate project for formatting, see <https://github.com/aspect-build/bazel-super-formatter#design>

[aspect cli]: https://docs.aspect.build/v/cli
[tricorder]: https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/43322.pdf
[reviewdog]: https://github.com/reviewdog/reviewdog

## Installation

Follow instructions from the release you wish to use:
<https://github.com/aspect-build/rules_lint/releases>
