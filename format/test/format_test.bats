# Simple test fixture that uses this "real" git repository.
# Ideally we would create self-contained "system under test" for each test case.
# That would let us test more scenarios with git, like deleted files.
bats_load_library "bats-support"
bats_load_library "bats-assert"

# No arguments: will use git ls-files
@test "should run prettier on javascript using git ls-files" {
    run bazel run //format/test:format_JavaScript_with_prettier
    assert_success

    assert_output --partial "+ prettier --write examples/nodejs/eslint.config.mjs"
    assert_output --partial "+ prettier --write examples/nodejs/src/(special_char)/[square]/hello.ts examples/nodejs/src/file-dep.ts examples/nodejs/src/file.ts"
    assert_output --partial "+ prettier --write examples/nodejs/src/hello.tsx"
    assert_output --partial "+ prettier --write examples/nodejs/src/hello.vue"
    assert_output --partial "+ prettier --write .bcr/metadata.template.json"
    assert_output --partial "+ prettier --write examples/nodejs/.swcrc"
    assert_output --partial "+ prettier --write examples/other_formatters/src/config.json5"
}

# File arguments: will filter with find
@test "should run prettier on javascript using find" {
    run bazel run //format/test:format_JavaScript_with_prettier README.md examples/nodejs/.eslintrc.cjs
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

@test "should run djlint on HTML Jinja templates" {
    run bazel run //format/test:format_HTML_Jinja_with_djlint
    assert_success

    assert_output --partial "+ djlint --format-css --format-js --reformat examples/other_formatters/src/hello.html.jinja"
}

@test "should run prettier on Markdown" {
    run bazel run //format/test:format_Markdown_with_prettier
    assert_success

    assert_output --partial "+ prettier --write .bcr/README.md CONTRIBUTING.md README.md"
}

@test "should run prettier on XML" {
    run bazel run //format/test:format_XML_with_prettier
    assert_success

    assert_output --partial "+ prettier --write examples/java/checkstyle-suppressions.xml"
}

@test "should run prettier on CSS" {
    run bazel run //format/test:format_CSS_with_prettier
    assert_success

    assert_output --partial "+ prettier --write examples/nodejs/src/clean.css examples/nodejs/src/hello.css"
    assert_output --partial "+ prettier --write examples/nodejs/src/hello.less"
    assert_output --partial "+ prettier --write examples/nodejs/src/hello.scss"
}

@test "should run cue fmt on CUE" {
    run bazel run //format/test:format_CUE_with_cue-fmt
    assert_success

    assert_output --partial "+ cue-fmt fmt examples/other_formatters/src/hello.cue"
}

@test "should run prettier on HTML" {
    run bazel run //format/test:format_HTML_with_prettier
    assert_success

    assert_output --partial "+ prettier --write examples/nodejs/src/index.html"
}

@test "should run prettier on GraphQL" {
    run bazel run //format/test:format_GraphQL_with_prettier
    assert_success

    assert_output --partial "+ prettier --write examples/other_formatters/src/hello.graphql"
}

@test "should run prettier on SQL" {
    run bazel run //format/test:format_SQL_with_prettier
    assert_success

    assert_output --partial "+ prettier --write examples/sql/src/hello.sql"
}

@test "should run ruff on Python" {
    run bazel run //format/test:format_Python_with_ruff
    assert_success

    assert_output --partial "+ ruff format --force-exclude examples/python/src/call_non_callable.py"
}

@test "should run taplo on TOML" {
    run bazel run //format/test:format_TOML_with_taplo
    assert_success

    assert_output --partial '+ taplo format _typos.toml examples/python/.ruff.toml examples/python/src/ruff.toml examples/python/src/subdir/ruff.toml examples/python/ty.toml examples/rust/.clippy.toml examples/toml/hello.toml'
}

@test "should run terraform fmt on HCL" {
    run bazel run //format/test:format_Terraform_with_terraform-fmt
    assert_success

    assert_output --partial "+ terraform-fmt fmt examples/terraform/hello.tf"
}

@test "should run jsonnet-fmt on Jsonnet" {
    run bazel run //format/test:format_Jsonnet_with_jsonnetfmt
    assert_success

    assert_output --partial "+ jsonnetfmt --in-place examples/other_formatters/src/hello.jsonnet examples/other_formatters/src/hello.libsonnet"
}

@test "should run java-format on Java" {
    run bazel run //format/test:format_Java_with_java-format
    assert_success

    assert_output --partial "+ java-format --replace examples/java/src/Bar.java examples/java/src/FileReaderUtil.java examples/java/src/Foo.java"
}

@test "should run ktfmt on Kotlin" {
    run bazel run //format/test:format_Kotlin_with_ktfmt
    assert_success

    assert_output --partial "+ ktfmt examples/kotlin/src/hello.kt"
}

@test "should run scalafmt on Scala" {
    run bazel run //format/test:format_Scala_with_scalafmt
    assert_success

    assert_output --partial "+ scalafmt --respect-project-filters examples/scala/src/hello.scala"
}

@test "should run gofmt on Go" {
    run bazel run //format/test:format_Go_with_gofmt
    assert_success

    assert_output --partial "+ gofmt -w examples/go/src/hello.go"
}

@test "should run clang-format on C++" {
    run bazel run //format/test:format_C++_with_clang-format
    assert_success

    assert_output --partial "+ clang-format -style=file --fallback-style=none -i examples/cpp/src/cpp/lib/get/get-time.cc"
}

@test "should run clang-format on Cuda" {
    run bazel run //format/test:format_Cuda_with_clang-format
    assert_success

    assert_output --partial "+ clang-format -style=file --fallback-style=none -i examples/cpp/src/hello.cu"
}

@test "should run shfmt on Shell" {
    run bazel run //format/test:format_Shell_with_shfmt
    assert_success

    assert_output --partial "+ shfmt -w --apply-ignore .github/workflows/release_prep.sh"
    assert_output --partial "examples/shell/src/hello.sh"
    assert_output --partial "examples/shell/src/hello_sh"
}

@test "should run swiftformat on Swift" {
    run bazel run //format/test:format_Swift_with_swiftformat
    assert_success

    assert_output --partial "+ swiftformat examples/swift/src/hello.swift"
}

@test "should run buf on Protobuf" {
    run bazel run //format/test:format_Protocol_Buffer_with_buf
    assert_success

    # Buf only formats one file at a time
    assert_output --partial "+ buf format --write --disable-symlinks --path examples/protobuf/src/file.proto"
    assert_output --partial "+ buf format --write --disable-symlinks --path examples/protobuf/src/unused.proto"
}

@test "should run yamlfmt on YAML" {
    run bazel run //format/test:format_YAML_with_yamlfmt
    assert_success

    assert_output --partial "+ yamlfmt .aspect/workflows/config.yaml"
}

@test "should run rustfmt on Rust" {
    run bazel run //format/test:format_Rust_with_rustfmt
    assert_success

    assert_output --partial "+ rustfmt examples/rust/src/bad_binary.rs examples/rust/src/bad_lib.rs examples/rust/src/ok_binary.rs"
}

@test "should run prettier on Gherkin" {
    run bazel run //format/test:format_Gherkin_with_prettier
    assert_success

    assert_output --partial "+ prettier --write examples/other_formatters/src/hello.feature"
}

@test "should run fantomas on F#" {
    run bazel run //format/test:format_F#_with_fantomas
    assert_success

    assert_output --partial "+ fantomas examples/fsharp/src/hello.fs"
}

@test "should run csharpier on C#" {
    run bazel run //format/test:format_C#_with_csharpier
    assert_success

    assert_output --partial "+ csharpier format examples/csharp/src/hello.cs"
}
