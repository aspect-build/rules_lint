This diagnostic to sarif implementation is based on https://github.com/psastras/sarif-rs/blob/main/sarif-fmt

The test data in `testdata/human` and `testdata/sarif` was taken from https://github.com/psastras/sarif-rs/blob/main/sarif-fmt/tests/clippy-test.rs so as to test that the javascript implementation matches the rust implementation.
However, it was modified to extract the rustc diagnostics from the cargo diagnostics (by extracting the `message` field in each diagnostic).

The test data in `testdata/patch` was taken by extracting the rustc clippy diagnostics in `examples/rust//src:binary_with_warning_and_error`.