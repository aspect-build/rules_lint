"Implementation of formatter_binary"

# Per the formatter design, each language can only have a single formatter binary
# Keys in this map must match the `case "$language" in` block in format.sh
TOOLS = {
    "JavaScript": "prettier",
    "Markdown": "prettier",
    "Python": "ruff",
    "Starlark": "buildifier",
    "Jsonnet": "jsonnetfmt",
    "Terraform": "terraform-fmt",
    "Kotlin": "ktfmt",
    "Java": "java-format",
    "Scala": "scalafmt",
    "Swift": "swiftformat",
    "Go": "gofmt",
    "SQL": "prettier",
    "Shell": "shfmt",
    "Protocol Buffer": "buf",
    "C++": "clang-format",
    "YAML": "yamlfmt",
    "Rust": "rustfmt",
}

DEFAULT_TOOL_LABELS = {
    "Jsonnet": "@multitool//tools/jsonnetfmt",
    "Go": "@multitool//tools/gofumpt",
    "Shell": "@multitool//tools/shfmt",
    "Terraform": "@multitool//tools/terraform",
    "YAML": "@multitool//tools/yamlfmt",
}

CHECK_FLAGS = {
    "buildifier": "-mode=check",
    "swiftformat": "--lint",
    "prettier": "--check",
    "ruff": "format --check --force-exclude",
    "shfmt": "--diff --apply-ignore",
    "java-format": "--set-exit-if-changed --dry-run",
    "ktfmt": "--set-exit-if-changed --dry-run",
    "gofmt": "-l",
    "buf": "format -d --exit-code",
    "terraform-fmt": "fmt -check -diff",
    "jsonnetfmt": "--test",
    "scalafmt": "--test",
    "clang-format": "--style=file --fallback-style=none --dry-run -Werror",
    "yamlfmt": "-lint",
    "rustfmt": "--write-mode=diff",
}

FIX_FLAGS = {
    "buildifier": "-mode=fix",
    "swiftformat": "",
    "prettier": "--write",
    # Force exclusions in the configuration file to be honored even when file paths are supplied
    # as command-line arguments; see
    # https://github.com/astral-sh/ruff/discussions/5857#discussioncomment-6583943
    "ruff": "format --force-exclude",
    # NB: apply-ignore added in https://github.com/mvdan/sh/issues/1037
    "shfmt": "-w --apply-ignore",
    "java-format": "--replace",
    "ktfmt": "",
    "gofmt": "-w",
    "buf": "format -w",
    "terraform-fmt": "fmt",
    "jsonnetfmt": "--in-place",
    "scalafmt": "",
    "clang-format": "-style=file --fallback-style=none -i",
    "yamlfmt": "",
    "rustfmt": "",
}

def to_attribute_name(lang):
    if lang == "C++":
        return "cc"
    return lang.lower().replace(" ", "_")
