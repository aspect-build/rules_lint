# How to Contribute

## Formatting

Starlark files should be formatted by buildifier.
We suggest using a pre-commit hook to automate this.
First [install pre-commit](https://pre-commit.com/#installation),
then run

```shell
pre-commit install
```

Otherwise later tooling on CI may yell at you about formatting/linting violations.

## Updating BUILD files

Some targets are generated from sources.
Currently this is just the `bzl_library` targets.
Run `aspect configure` to keep them up-to-date.

## Using this as a development dependency of other rules

You'll commonly find that you develop in another WORKSPACE, such as
some other ruleset that depends on rules_lint, or in a nested
WORKSPACE in the integration_tests folder.

To always tell Bazel to use this directory rather than some release
artifact or a version fetched from the internet, run this from this
directory:

```sh
OVERRIDE="--override_repository=rules_lint=$(pwd)/rules_lint"
echo "common $OVERRIDE" >> ~/.bazelrc
```

This means that any usage of `@rules_lint` on your system will point to this folder.

## Releasing

**Easiest**: if the new version can be determined automatically from the commit history, just navigate to
https://github.com/aspect-build/rules_lint/actions/workflows/tag.yaml
and press the "Run workflow" button.

If you need control over the next release version, for example when making a release candidate for a new major,
then: tag the repo and push the tag, for example

```sh
% git fetch
% git tag v1.0.0-rc0 origin/main
% git push origin v1.0.0-rc0
```

Then watch the automation run on GitHub actions which creates the release.

## Recording a demo

Install from https://asciinema.org/
Then cd example and start recording, pasting these commands:

figlet "Linting with Bazel can be nice!"
figlet "The BUILD file is clean"
cat src/BUILD.bazel
figlet "We can run lint.sh on the targets"
./lint.sh src:all
figlet "it linted proto, python, and JS!"
figlet "' lint ' command with an Aspect CLI plugin ->"
bazel lint src:all
