# Simple test fixture that uses this "real" git repository.
# Ideally we would create self-contained "system under test" for each test case.
# That would let us test more scenarios with git, like deleted files.
bats_load_library "bats-support"
bats_load_library "bats-assert"

# No arguments: will use git ls-files
@test "should run prettier on javascript using git ls-files" {
    run bazel run //format/test:format_JavaScript_with_prettier
    assert_success

    assert_output --partial "+ prettier --write example/.eslintrc.cjs"
    assert_output --partial "+ prettier --write example/src/file.ts example/test/no_violations.ts"
    assert_output --partial "+ prettier --write example/src/hello.tsx"
    assert_output --partial "+ prettier --write .bcr/metadata.template.json"
    assert_output --partial "+ prettier --write example/src/hello.css"
    assert_output --partial "+ prettier --write example/src/index.html"
}

# File arguments: will filter with find
@test "should run prettier on javascript using find" {
    run bazel run //format/test:format_JavaScript_with_prettier README.md example/.eslintrc.cjs
    assert_success

    assert_output --partial "README.md"
    refute_output --partial "file.ts"
}

@test "should run buildozer on starlark" {
    run bazel run //format/test:format_Starlark_with_buildifier
    assert_success

    assert_output --partial "+ buildifier -mode=fix BUILD.bazel"
    assert_output --partial "format/private/BUILD.bazel"
}

@test "should run prettier on Markdown" {
    run bazel run //format/test:format_Markdown_with_prettier
    assert_success

    assert_output --partial "+ prettier --write .bcr/README.md CONTRIBUTING.md README.md"
}

@test "should run prettier on SQL" {
    run bazel run //format/test:format_SQL_with_prettier
    assert_success

    assert_output --partial "+ prettier --write example/src/hello.sql"
}

@test "should run ruff on Python" {
    run bazel run //format/test:format_Python_with_ruff
    assert_success

    assert_output --partial "+ ruff format --force-exclude example/src/subdir/unused_import.py"
}

@test "should run terraform fmt on HCL" {
    run bazel run //format/test:format_Terraform_with_terraform-fmt
    assert_success

    assert_output --partial "+ terraform-fmt fmt example/src/hello.tf"
}

@test "should run jsonnet-fmt on Jsonnet" {
    run bazel run //format/test:format_Jsonnet_with_jsonnetfmt
    assert_success

    assert_output --partial "+ jsonnetfmt --in-place example/src/hello.jsonnet example/src/hello.libsonnet"
}

@test "should run java-format on Java" {
    run bazel run //format/test:format_Java_with_java-format
    assert_success

    assert_output --partial "+ java-format --replace example/src/Foo.java"
}

@test "should run ktfmt on Kotlin" {
    run bazel run //format/test:format_Kotlin_with_ktfmt
    assert_success

    assert_output --partial "+ ktfmt example/src/hello.kt"
}

@test "should run scalafmt on Scala" {
    run bazel run //format/test:format_Scala_with_scalafmt
    assert_success

    assert_output --partial "+ scalafmt example/src/hello.scala"
}

@test "should run gofmt on Go" {
    run bazel run //format/test:format_Go_with_gofmt
    assert_success

    assert_output --partial "+ gofmt -w example/src/hello.go"
}

@test "should run clang-format on C++" {
    run bazel run //format/test:format_C++_with_clang-format
    assert_success

    assert_output --partial "+ clang-format -style=file --fallback-style=none -i example/src/hello.cpp"
}

@test "should run shfmt on Shell" {
    run bazel run //format/test:format_Shell_with_shfmt
    assert_success

    assert_output --partial "+ shfmt -w --apply-ignore .github/workflows/release_prep.sh"
}

@test "should run swiftformat on Swift" {
    run bazel run //format/test:format_Swift_with_swiftformat
    assert_success

    assert_output --partial "+ swiftformat example/src/hello.swift"
}

@test "should run buf on Protobuf" {
    run bazel run //format/test:format_Protocol_Buffer_with_buf
    assert_success

    # Buf only formats one file at a time
    assert_output --partial "+ buf format -w example/src/file.proto"
    assert_output --partial "+ buf format -w example/src/unused.proto"
}

@test "should run yamlfmt on YAML" {
    run bazel run //format/test:format_YAML_with_yamlfmt
    assert_success

    assert_output --partial "+ yamlfmt .bcr/config.yml"
}

@test "should run rustfmt on Rust" {
    run bazel run //format/test:format_Rust_with_rustfmt
    assert_success

    assert_output --partial "+ rustfmt example/src/hello.rs"
}
