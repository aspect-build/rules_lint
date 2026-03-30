"""Example .bzl file with a Buildifier warning."""

def bad_macro():
    deps = []
    deps += [":dep"]
    return deps
