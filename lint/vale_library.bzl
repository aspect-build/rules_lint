"""Vale styles library

Vendored from https://raw.githubusercontent.com/errata-ai/styles/master/library.json
Then the url fields are converted from latest to a format string, and sha256sums added.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

VALE_STYLE_DATA = [
    {
        "name": "Google",
        "description": "A Vale-compatible implementation of the Google Developer Documentation Style Guide.",
        "homepage": "https://github.com/errata-ai/Google",
        "integrity": "sha256-XxUQYDM3uzLzySeHKnPnv9SU161NTxD7qJYalLpIHb4=",
        "version": "v0.4.2",
        "url": "https://github.com/errata-ai/Google/releases/download/{}/Google.zip",
    },
    {
        "name": "Joblint",
        "description": "Test tech job posts for issues with sexism, culture, expectations, and recruiter fails.",
        "homepage": "https://github.com/errata-ai/Joblint",
        "integrity": "sha256-pDIqdlgt/xAXp9CWXmxQqstd+Vso8PMWFu0J1BsVgeU=",
        "version": "v0.4.1",
        "url": "https://github.com/errata-ai/Joblint/releases/download/{}/Joblint.zip",
    },
    {
        "name": "Microsoft",
        "description": "A Vale-compatible implementation of the Microsoft Writing Style Guide.",
        "homepage": "https://github.com/errata-ai/Microsoft",
        "integrity": "sha256-YB00NPHYLt+mDLdDTiy9XyYlQn9Tl+EATD5+cwvlp8k=",
        "version": "v0.10.1",
        "url": "https://github.com/errata-ai/Microsoft/releases/download/{}/Microsoft.zip",
    },
    {
        "name": "proselint",
        "description": "proselint places the world's greatest writers and editors by your side.",
        "homepage": "https://github.com/errata-ai/proselint",
        "integrity": "sha256-0sQRvTg6xUd2L9HxMFBuWXQVw3M2StYLgnR4eGaBuno=",
        "version": "v0.3.3",
        "url": "https://github.com/errata-ai/proselint/releases/download/{}/proselint.zip",
    },
    {
        "name": "write-good",
        "description": "Naive linter for English prose for developers who can't write good.",
        "homepage": "https://github.com/errata-ai/write-good",
        "integrity": "sha256-4OhhIyZve4I3joSmGDu1XZjJthUovLc00XRy68Is1BU=",
        "version": "v0.4.0",
        "url": "https://github.com/errata-ai/write-good/releases/download/{}/write-good.zip",
    },
    {
        "name": "alex",
        "description": "Catch insensitive, inconsiderate writing.",
        "homepage": "https://github.com/errata-ai/alex",
        "integrity": "sha256-wREfIkw88Fag5g3GzuZ1OwDCOolVx9+VI/P29AtnePw=",
        "version": "v0.2.1",
        "url": "https://github.com/errata-ai/alex/releases/download/{}/alex.zip",
    },
    {
        "name": "Readability",
        "description": "Vale-compatible implementations of many popular readability metrics.",
        "homepage": "https://github.com/errata-ai/Readability",
        "integrity": "sha256-++F4tLZIxNQbtyzuUzrd/Y9Rzw89HwrfoIgIdwtBgQY=",
        "version": "v0.1.1",
        "url": "https://github.com/errata-ai/readability/releases/download/{}/Readability.zip",
    },
    {
        "name": "Hugo",
        "description": "Adds support for Hugo shortcodes and other non-standard markup.",
        "homepage": "https://github.com/errata-ai/Hugo",
        "integrity": "sha256-1xUjVXmEbh+sAeIKxruxwrLdEUz7M8SL0EysXUv+900=",
        "version": "v0.2.0",
        "url": "https://github.com/errata-ai/Hugo/releases/download/{}/Hugo.zip",
    },
    {
        "name": "RedHat",
        "description": "A Vale-compatible implementation of the Red Hat Supplementary Style Guide.",
        "homepage": "https://redhat-documentation.github.io/vale-at-red-hat/docs/user-guide/redhat-style-for-vale/",
        "integrity": "sha256-sZvjP/ahqSoua/OEdVC/oALUlFDXddut4pmKr5PWanU=",
        "version": "v431",
        "url": "https://github.com/redhat-documentation/vale-at-red-hat/releases/download/{}/RedHat.zip",
    },
    {
        "name": "AsciiDoc",
        "description": "A Vale-compatible implementation of select AsciiDoc syntax rules.",
        "homepage": "https://redhat-documentation.github.io/vale-at-red-hat/docs/main/user-guide/asciidoc-style-for-vale/",
        "integrity": "sha256-QbgpcmzACPYzpfEoUQx/69Pu73mqbgQnmqh3YQjY6hI=",
        "version": "v431",
        "url": "https://github.com/redhat-documentation/vale-at-red-hat/releases/download/{}/AsciiDoc.zip",
    },
    {
        "name": "OpenShiftAsciiDoc",
        "description": "A Vale-compatible implementation of select AsciiDoc guidance from the OpenShift docs contributor guidelines.",
        "homepage": "https://redhat-documentation.github.io/vale-at-red-hat/docs/main/user-guide/openshift-asciidoc-style-for-vale/",
        "integrity": "sha256-F6LMXFKfHIaFhG26BazlN3W2m1DN628f0YTe+An1TSQ=",
        "version": "v431",
        "url": "https://github.com/redhat-documentation/vale-at-red-hat/releases/download/{}/OpenShiftAsciiDoc.zip",
    },
]

VALE_STYLES = [s["name"] for s in VALE_STYLE_DATA]

def fetch_styles():
    for style in VALE_STYLE_DATA:
        maybe(
            http_archive,
            name = "vale_" + style["name"],
            integrity = style["integrity"],
            # Note: this is actually a directory, not a file
            build_file_content = """exports_files(["{}"])""".format(style["name"]),
            url = style["url"].format(style["version"]),
        )
