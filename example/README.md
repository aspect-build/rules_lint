# Example of using rules_lint

The `src/` folder contains a project that we want to lint.
It contains sources in multiple languages.

### With Aspect CLI

_linux/mac only_

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

## Windows:

### Setup
If running this repo on Windows, run `configure.bat` to set it up before running 
any bazel commands. This removes features that are not supported yet on this platform.

### Run
Aspect CLI is not supported [[aspect-cli#598](https://github.com/aspect-build/aspect-cli/issues/598)]. Instead, use the shell script:

- ensure jq is on the path
- `set BAZEL_SH=c:\msys64\usr\bin\bash.exe` _git bash has issues_
- rules_lint/example> `bash lint.sh src:all`

linters that are not yet supported OOTB on Windows are not included in lint.sh. You may still be able to use them on Windows by manually configuring
their binaries and providing them to the appropriate rules.

#### Linter issues on Windows:

These linters do not currently work OOTB:
- buf - the buf toolchain doesn't auto-expose its tools [[rules_buf#78](https://github.com/bufbuild/rules_buf/issues/78)]
- eslint - depends on rules_js which doesn't currently support windows due to an issue with bsdtar.exe [[rules_js#1739](https://github.com/aspect-build/rules_js/issues/1739)]
- ktlint - also fails due to bsdtar.exe

Whilst these linters do not work here OOTB, you may be able to get them to work by providing your own versions to the toolchain.

#### Format issues on Windows:
- format does not currently work due to an issue with rules_multirun: [[rules_multirun#56](https://github.com/keith/rules_multirun/issues/56)]

## ESLint

This folder simply follows the instructions at https://typescript-eslint.io/getting-started
to create the ESLint setup.

## Buf
