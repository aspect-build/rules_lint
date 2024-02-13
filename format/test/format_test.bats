# Simple test fixture that uses this "real" git repository.
# Ideally we would create self-contained "system under test" for each test case.
# That would let us test more scenarios with git, like deleted files.
bats_load_library "bats-support"
bats_load_library "bats-assert"

# No arguments: will use git ls-files
@test "should run prettier on javascript using git ls-files" {
    run bazel run //format/test:format_javascript
    assert_success

    assert_output --partial "Formatting JavaScript with Prettier..."
    assert_output --partial "+ prettier --write example/.eslintrc.cjs"
    assert_output --partial "Formatting TypeScript with Prettier..."
    assert_output --partial "+ prettier --write example/src/file.ts example/test/no_violations.ts"
    assert_output --partial "Formatting TSX with Prettier..."
    assert_output --partial "+ prettier --write example/src/hello.tsx"
    assert_output --partial "Formatting JSON with Prettier..."
    assert_output --partial "+ prettier --write .bcr/metadata.template.json"
    assert_output --partial "Formatting CSS with Prettier..."
    assert_output --partial "+ prettier --write example/src/hello.css"
    assert_output --partial "Formatting HTML with Prettier..."
    assert_output --partial "+ prettier --write example/src/index.html"
}

# File arguments: will filter with find
@test "should run prettier on javascript using find" {
    run bazel run //format/test:format_javascript README.md example/.eslintrc.cjs
    assert_success

    assert_output --partial "Formatting JavaScript with Prettier..."
    refute_output --partial "Formatting TypeScript with Prettier..."
}

@test "should run buildozer on starlark" {
    run bazel run //format/test:format_starlark
    assert_success

    assert_output --partial "Formatting Starlark with Buildifier..."
    assert_output --partial "+ buildifier -mode=fix BUILD.bazel"
    assert_output --partial "format/private/BUILD.bazel"
}

@test "should run prettier on Markdown" {
    run bazel run //format/test:format_markdown
    assert_success

    assert_output --partial "Formatting Markdown with Prettier..."
    assert_output --partial "+ prettier --write .bcr/README.md CONTRIBUTING.md README.md"
}

@test "should run prettier on SQL" {
    run bazel run //format/test:format_sql
    assert_success

    assert_output --partial "Formatting SQL with Prettier..."
    assert_output --partial "+ prettier --write example/src/hello.sql"
}

@test "should run ruff on Python" {
    run bazel run //format/test:format_python
    assert_success

    assert_output --partial "Formatting Python with Ruff..."
    assert_output --partial "+ ruff format --force-exclude example/src/subdir/unused_import.py"
}

@test "should run terraform fmt on HCL" {
    run bazel run //format/test:format_hcl
    assert_success

    assert_output --partial "Formatting Terraform with terraform fmt..."
    assert_output --partial "+ terraform-fmt fmt example/src/hello.tf"
}

@test "should run jsonnet-fmt on Jsonnet" {
    run bazel run //format/test:format_jsonnet
    assert_success

    assert_output --partial "Formatting Jsonnet with jsonnetfmt..."
    assert_output --partial "+ jsonnetfmt --in-place example/src/hello.jsonnet example/src/hello.libsonnet"
}

@test "should run java-format on Java" {
    run bazel run //format/test:format_java
    assert_success

    assert_output --partial "Formatting Java with java-format..."
    assert_output --partial "+ java-format --replace example/src/Foo.java"
}

@test "should run ktfmt on Kotlin" {
    run bazel run //format/test:format_kotlin
    assert_success

    assert_output --partial "Formatting Kotlin with ktfmt..."
    assert_output --partial "+ ktfmt example/src/hello.kt"
}

@test "should run scalafmt on Scala" {
    run bazel run //format/test:format_scala
    assert_success

    assert_output --partial "Formatting Scala with scalafmt..."
    assert_output --partial "+ scalafmt example/src/hello.scala"
}

@test "should run gofmt on Go" {
    run bazel run //format/test:format_go
    assert_success

    assert_output --partial "Formatting Go with gofmt..."
    assert_output --partial "+ gofmt -w example/src/hello.go"
}

@test "should run clang-format on C++" {
    run bazel run //format/test:format_cc
    assert_success

    assert_output --partial "Formatting C++ with clang-format..."
    assert_output --partial "+ clang-format -style=file --fallback-style=none -i example/src/hello.cpp"
}

@test "should run shfmt on Shell" {
    run bazel run //format/test:format_sh
    assert_success

    assert_output --partial "Formatting Shell with shfmt..."
    assert_output --partial "+ shfmt -w .github/workflows/release_prep.sh"
}

@test "should run swiftformat on Swift" {
    run bazel run //format/test:format_swift
    assert_success

    # The real swiftformat prints the "Formatting..." output so we don't
    assert_output --partial "+ swiftformat example/src/hello.swift"
}

@test "should run buf on Protobuf" {
    run bazel run //format/test:format_protobuf
    assert_success

    assert_output --partial "Formatting Protocol Buffer with buf..."
    # Buf only formats one file at a time
    assert_output --partial "+ buf format -w example/src/file.proto"
    assert_output --partial "+ buf format -w example/src/unused.proto"
}
