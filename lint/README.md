# Adding a new linter

## Design invariants

These will be part of reviewing PRs to this repo:

1. Take care with dependencies. Avoid adding to `MODULE.bazel` if possible.
   In cases where a tool is a statically-linked binary, it can be added to the `multitool.lock.json` file
   to conveniently provide it to users.
   In other cases where a language ecosystem's package manager is involved,
   the tool should be setup "in userland", which means adding it to the `example` folder.
   Note that this distinction also determines whether users control the version of the tool.

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
   It must always return the correct output groups, which is easiest by using the
   `report_files` helper in `//lint/private:lint_aspect.bzl`.
   The simple lint.sh also relies on the report output filenames containing `AspectRulesLint`, which comes from
   the convention that `AspectRulesLint` is the prefix for all rules_lint linter action mnemonics.

3. A `lint_my_linter_aspect` factory function. This is a higher-order function that returns an aspect.
   This pattern allows us to capture arguments like labels and toolchains which aren't legal
   in public aspect attributes.

Then wire this up into the example and confirm that you can get the same linter result as you did in
step 1.

## Step 3: docs

Add a rule in the `docs/` folder matching the existing ones, so that the API docs are auto-generated.
Run `cd docs; bazel run update` to create the Markdown file.

Also add your new linter to the README.

## Step 4: tests

Add integration tests under the example/test folder. It should cover both the human-readable and machine-readable output groups.

## Step 5: Send the PR!

We'd love to make your linter available to everyone.
