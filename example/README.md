# Example of using rules_lint

The `src/` folder contains a project that we want to lint.
It contains sources in multiple languages.

The `terraform/` directory demonstrates formatting and linting Terraform modules via
[`rules_tf`](https://github.com/yanndegat/rules_tf). The providers and toolchains are configured in
`MODULE.bazel`, so the examples work out-of-the-box with `bazel run` and `bazel build`.

### With Aspect CLI

Run `bazel lint src:all`

> If the 'lint' command isn't found, make sure you have a new enough version of Aspect CLI.

### Without Aspect CLI

There's a shell script to approximate what our Aspect CLI plugin does:

```
rules_lint/example$ ./lint.sh src:all
INFO: Analyzed 4 targets (0 packages loaded, 0 targets configured).
INFO: Found 4 targets...
INFO: Elapsed time: 0.063s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
From /shared/cache/bazel/user_base/b6913b1339fd4037a680edabc6135c1d/execroot/_main/bazel-out/k8-fastbuild/bin/src/ts.eslint-report.txt:

/shared/cache/bazel/user_base/b6913b1339fd4037a680edabc6135c1d/sandbox/linux-sandbox/861/execroot/_main/bazel-out/k8-fastbuild/bin/src/file.ts
  2:7  error  Type string trivially inferred from a string literal, remove type annotation  @typescript-eslint/no-inferrable-types

✖ 1 problem (1 error, 0 warnings)
  1 error and 0 warnings potentially fixable with the `--fix` option.

From /shared/cache/bazel/user_base/b6913b1339fd4037a680edabc6135c1d/execroot/_main/bazel-out/k8-fastbuild/bin/src/foo_proto.buf-report.txt:
--buf-plugin_out: src/file.proto:1:1:Import "src/unused.proto" is unused.

```

Terraform modules can be linted and formatted the same way. For example:

```
# Lint the sample module with TFLint
bazel build //terraform/aws_subnet:module --aspects //tools/lint:linters.bzl%tflint --output_groups=rules_lint_human

# Apply formatting to Terraform sources
bazel run //:format -- terraform/aws_subnet/main.tf
```

## ESLint

This folder simply follows the instructions at https://typescript-eslint.io/getting-started
to create the ESLint setup.

## Buf
