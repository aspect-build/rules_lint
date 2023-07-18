"Public API re-exports"

load("//lint/private:eslint.bzl", "eslint_aspect_impl")

def eslint_aspect(binary, config):
    """A factory function to create a linter aspect.
    """
    return aspect(
        implementation = eslint_aspect_impl,
        # attr_aspects = ["deps"],
        attrs = {
            "_eslint": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_file": attr.label(
                default = config,
                allow_single_file = True,
            ),
        },
    )
