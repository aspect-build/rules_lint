# Adding a new formatter

See the "Design invariants" section in the [new linter doc](../lint/README.md).
This guidance applies for formatters as well.

We generally avoid offering users two different formatters for the same language.
It might be okay if the formatters have different strictness (like gofmt vs gofumpt)
or if they format different language dialects (each Hashicorp Config Language tool
has a different formatter).

Start in `format/private/formatter_binary.bzl`. This has some dictionaries that
define the tool used for each language.

`format/private/format.sh` may also need a small change to wire up the file extensions.
Run `format/private/mirror_linguist_languages.sh` to get a "canonical" list of
extensions used for this language.

In the `example` folder, add source files that demonstrate incorrect formatting
and verify that the `bazel run format` command corrects it.

Add a new test case in `format/test/format_test.bats` so that we have some automated
testing that the formatter works.

Update the `README.md` to include your formatter in the table.
