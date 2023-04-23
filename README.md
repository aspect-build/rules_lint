# Template for Bazel rules

Copy this template to create a Bazel ruleset.

Features:

- follows the official style guide at https://docs.bazel.build/versions/main/skylark/deploying.html
- allows for both WORKSPACE.bazel and bzlmod (MODULE.bazel) usage
- includes Bazel formatting as a pre-commit hook (using [buildifier])
- includes stardoc API documentation generator
- includes typical toolchain setup
- CI configured with GitHub Actions
- Release using GitHub Actions just by pushing a tag

See https://docs.bazel.build/versions/main/skylark/deploying.html#readme

[buildifier]: https://github.com/bazelbuild/buildtools/tree/master/buildifier#readme

Ready to get started? Copy this repo, then

1. search for "com_myorg_rules_mylang" and replace with the name you'll use for your workspace
1. search for "myorg" and replace with GitHub org
1. search for "mylang" and replace with the language/tool your rules are for
1. rename directory "mylang" similarly
1. run `pre-commit install` to get lints (see CONTRIBUTING.md)
1. if you don't need to fetch platform-dependent tools, then remove anything toolchain-related.
1. update the `actions/cache@v2` bazel cache key in [.github/workflows/ci.yaml](.github/workflows/ci.yaml) and [.github/workflows/release.yml](.github/workflows/release.yml) to be a hash of your source files.
1. (optional) install the [Renovate app](https://github.com/apps/renovate) to get auto-PRs to keep the dependencies up-to-date.
1. delete this section of the README (everything up to the SNIP).

---- SNIP ----

# Bazel rules for mylang

## Installation

From the release you wish to use:
<https://github.com/myorg/rules_mylang/releases>
copy the WORKSPACE snippet into your `WORKSPACE` file.

To use a commit rather than a release, you can point at any SHA of the repo.

For example to use commit `abc123`:

1. Replace `url = "https://github.com/myorg/rules_mylang/releases/download/v0.1.0/rules_mylang-v0.1.0.tar.gz"` with a GitHub-provided source archive like `url = "https://github.com/myorg/rules_mylang/archive/abc123.tar.gz"`
1. Replace `strip_prefix = "rules_mylang-0.1.0"` with `strip_prefix = "rules_mylang-abc123"`
1. Update the `sha256`. The easiest way to do this is to comment out the line, then Bazel will
    print a message with the correct value. Note that GitHub source archives don't have a strong
    guarantee on the sha256 stability, see
    <https://github.blog/2023-02-21-update-on-the-future-stability-of-source-code-archives-and-hashes/>
