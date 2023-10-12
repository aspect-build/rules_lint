# Adding a new linter

## Design invariants

These will be part of reviewing PRs to this repo:

1. Avoid adding dependencies to rules_lint, they belong in the example instead. For example in adding
   eslint or flake8, it's up to the user to provide us the binary to run.
   This ensures that the user can select the versions of their tools and the toolchains used to run them
   rather than us baking these into rules_lint.

2. Study the installation, CLI usage, and configuration documentation for the linter you want to add.
   We'll need to adapt these to Bazel's idioms. As much as possible, copy or link to this documentation
   in your code so that maintainers can understand it.
   Usage of the linter under Bazel should be as similar as possible to how it's used outside Bazel,
   so we don't end up with a unique bug "surface area" that only Bazel users encounter.

## Step 1: Run linter in the example

In the example folder, install the tool the same way a user would. We need an executable target
(typically a `*_binary`) that can be passed to our aspect factory function.

For example, to install flake8, we need to do the normal install for rules_python,
create a `requirements_lock.txt` file, call `pip_parse` to install it, and find the `entry_point`
function that gives us a `py_binary` for it.

Add a config file for the linter following their documentation. We want users to be able to continue
running the linter outside Bazel (e.g. using their editor plugin) and they should be assured that
they get the same result.

Add a file under `src/` that violates one of the linter checks, and add a comment describing how we
can see the linter running. This should basically be a "demo" of how the linter works, without
rules_lint getting involved yet.

Take a look at this commit as an example of step 1:
https://github.com/aspect-build/rules_lint/commit/7365b82957dd60898ef1051f5ae94539714a38f4

Please check in a commit at this point to make your PR easier for us to review.

## Step 2: create linter

Add the new_linter.bzl file in this folder.

Add these three things:

1. A `my_linter_action` function which declares one or more actions with `ctx.actions.run` or `ctx.actions.run_shell`.
   It should accept the report output as a parameter.
   You can use the "demo" from step 1 to guide you in setting the command-line options for the linter CLI.
   Note: this function provides a reusable API for developers who want to use flake8 in a different way than we prescribe with aspects.

2. A `_my_linter_aspect_impl` function, following the https://bazel.build/extending/aspects#aspect_implementation API.
   This is responsible for selecting which rule types in the graph it "knows how to lint".
   It should call the `my_linter_action` function.
   It must always return a `report` output group.
   Currently we also rely on the report output file being named following the convention `*-report.txt`, though this is
   a design smell.

3. A `my_linter_aspect` factory function. This is a higher-order function that returns an aspect.
   This pattern allows us to capture arguments like labels and toolchains which aren't legal
   in public aspect attributes.

Then wire this up into the example and confirm that you can get the same linter result as you did in
step 1.

Take a look at this commit as an example of step 2:
https://github.com/aspect-build/rules_lint/commit/29d275bcf7ecf5b99c6bff6913322fe1909302eb

## Step 3: docs

Add a rule in the `docs/` folder matching the existing ones, so that the API docs are auto-generated.
Run `bazel run docs:update` to create the Markdown file.

Also add your new linter to the README.

Here's a commit showing what it should look like:
https://github.com/aspect-build/rules_lint/commit/c3bf01a39c2e68b0b37918620aeafbf8ef0b2d85

## Step 4: Send the PR!

We'd love to make your linter available to everyone.
