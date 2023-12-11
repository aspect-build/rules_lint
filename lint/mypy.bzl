"""API for declaring a mypy lint aspect that visits py_library rules.

Typical usage:

```
load("@aspect_rules_lint//lint:mypy.bzl", "mypy_aspect")

mypy = mypy_aspect(
    binary = "@@//:mypy",
    configs = "@@//:pyproject.toml",
)
```

Optional: enable it in `.bazelrc`:

```
# Add mypy type-check validation actions to py_library targets.
# Disable for a particular build with --norun_validations
build --aspects=//tools:lint.bzl%mypy
```

### Reporting

Unlike most linters hosted in rules_lint, mypy produces only error semantics.
That means that typecheck violations will input_depsets in failed build actions, rather than
a report of warnings which can be handled in various ways.
See https://github.com/aspect-build/rules_lint/blob/main/docs/linting.md

However, it reports the violations using Bazel's Validation Actions feature, which means
you can pass the `--norun_validations` flag to skip type-checking for a particular build.

### Acknowledgements

This code inspired from https://github.com/bazel-contrib/bazel-mypy-integration
Thanks to the [contributors](https://github.com/bazel-contrib/bazel-mypy-integration/graphs/contributors)
especially [Jonathon Belotti](https://github.com/thundergolfer) and [David Zbarsky](https://github.com/dzbarsky).

### TODO

- Allow configured typeshed repo, e.g. args.add("--custom-typeshed-dir", "external/my_typeshed")
- Avoid invalidating caches whenever mypy.ini changes
- Remote cache: bootstrap the stdlib since it will remain in cache, making other actions slightly faster
- Later: Generate `.pyi` outputs: optimization to avoid as much invalidation
  when only implementation bodies change, at the cost of an extra mypy action.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")

_MNEMONIC = "mypy"
MypyInfo = provider(doc = "Python typechecking data", fields = {
    "transitive_cache_map": "depset: transitive --cache-map json files produced by deps",
})

def mypy_info(direct, deps):
    return MypyInfo(
        transitive_cache_map = depset(
            direct = direct,
            transitive = [d[MypyInfo].transitive_cache_map for d in deps if MypyInfo in d],
        ),
    )

def _extract_transitive_inputs(deps):
    input_depsets = []
    for dep in deps:
        # Supply the --cache-map files from transitives
        if MypyInfo in dep:
            input_depsets.append(dep[MypyInfo].transitive_cache_map)

        # NB: relies on PyInfo being a Bazel global symbol, one day we should be forced to load it
        # TODO: maybe we can avoid passing .py source files when the cache-map files were found?
        if PyInfo in dep:
            input_depsets.append(dep[PyInfo].transitive_sources)

            # rules_python puts .pyi files into the data attribute of a py_library
            # so the transitive_sources is not sufficient.
            # TODO: should we change rules_python to pass .pyi files in some provider?
            if dep.label.workspace_root.startswith("external/"):
                # includes:
                # external/rules_python~0.26.0~pip~pip_39_types_requests/site-packages/requests-stubs/utils.pyi
                input_depsets.append(dep[DefaultInfo].default_runfiles.files)

    return input_depsets

def mypy_action(ctx, executable, srcs, deps, configs):
    """Run mypy as an action under Bazel.

    See https://mypy.readthedocs.io/en/stable/command_line.html

    Args:
        ctx: Bazel Rule or Aspect evaluation context
        executable: label of the the mypy program
        srcs: python files to be linted
        deps: the deps of the py_library or py_binary so mypy can read dependent types
        configs: label(s) of mypy config file(s)

    Returns:
        Providers, including a MypyInfo provider to propagate data to dependents and a Validation output group
    """
    inputs = depset(srcs + configs, transitive = _extract_transitive_inputs(deps))

    # Imports tells us how to construct a rules_python-compatible PYTHONPATH:
    # https://github.com/bazelbuild/rules_python/blob/5ba63a88d44e80255fafdfb8fefe4c76967ee3e0/python/private/common/attributes_bazel.bzl#L19
    # TODO: try to setup a venv like rules_py so mypy can just run with its normal path resolution?
    # depset(["rules_python~0.26.0~pip~pip_39_urllib3/site-packages", "rules_python~0.26.0~pip~pip_39_types_requests/site-packages"])
    transitive_imports = depset(transitive = [dep[PyInfo].imports for dep in deps if PyInfo in dep])

    cache_map_outputs = []
    args = ctx.actions.args()

    # We are going to have a lot of argv in typical cases due to --cache-map triples.
    # Fortunately mypy uses argparse, which accepts a flagfile:
    # https://docs.python.org/3/library/argparse.html#fromfile-prefix-chars
    args.use_param_file("@%s", use_always = True)
    args.set_param_file_format("multiline")

    # TODO:
    # Merge srcs and stub_srcs -- when foo.py and foo.pyi are both present, only keep the latter.
    args.add_all(srcs)

    # TODO: do we need to support bazel's "implicit __init__.py convention"?
    # It seems that `--incompatible_default_to_explicit_init_py` is now preferred based on
    # https://github.com/bazelbuild/bazel/issues/7386#issuecomment-1806973756
    #
    # --package-root adds a directory below which directories are considered
    # packages even without __init__.py.  May be repeated.
    # args.add("--package-root")

    # Skip cache internal consistency checks based on mtime
    args.add("--skip-cache-mtime-checks")

    # Undocumented flag, see https://github.com/python/mypy/pull/4759
    # The --bazel flag make cache files hermetic by using relative paths and setting mtime to zero;
    # effectively the presence of a cache file prevents reading of the source file
    # (though the source file must still exist).
    args.add("--bazel")

    # Undocumented flag, see https://github.com/python/mypy/pull/4759
    # The --cache-map flag specifies a mapping from source files to cache files that overrides the
    # usual way of finding the locations for cache files; e.g.
    # mypy --cache-map foo.py foo.meta.json foo.data.json -- foo.py
    # There must be any number of triples (source, meta, data) with the additional constraints that
    # the source must end in .py or .pyi, meta must end in .meta.json,
    # and data must end in .data.json. For files in the cache map, the default cache directory
    # (--cache-dir) is ignored, and if the cache files named in the --cache-map don't exist
    # they will be written. For files not in the cache map, the --cache-dir is still used.
    args.add("--cache-map")

    # TODO: also need to construct the cache-map for .py files from deps, as seen from --verbose:
    # LOG:  Could not load cache for src.py_types.testing_deps.foo.fizz: src/py_types/testing_deps/foo/fizz.meta.json
    # LOG:  Metadata not found for src.py_types.testing_deps.foo.fizz
    for src in srcs:
        args.add(src)

        # NB: handle //path/to/package:subdir/file.py -> subdir/file.py
        path = paths.relativize(src.path, ctx.label.package)
        for kind in ("meta", "data"):
            # Note, this assumes every source file has a single mypy aspect producing these output files
            # For subdir/file.py, declare subdir/file.meta.json
            # If this is a problem, we could re-root these outputs beneath a target-specific tree
            file = ctx.actions.declare_file(paths.replace_extension(path, ".%s.json" % kind))
            cache_map_outputs.append(file)
            args.add(file)

    # Without this option, mypy will print on success, which will spam the Bazel output:
    # Success: no issues found in 1 source file
    args.add("--no-error-summary")

    # Enable with --aspects_parameters=rules_lint_verbose=True
    if ctx.attr.rules_lint_verbose:
        args.add("--verbose")

    # TODO: need some of these? Seen at RH
    # COVERAGE_FLAGS=(
    #     --linecount-report $report_output_dir
    #     --linecoverage-report $report_output_dir
    #     --lineprecision-report $report_output_dir
    #     --any-exprs-report $report_output_dir
    # )

    ctx.actions.run(
        inputs = inputs,
        outputs = cache_map_outputs,
        executable = executable,
        arguments = [args],
        env = {
            # TODO: investigate a more robust way to construct this, and avoid the length of the
            # value overflowing the operating system limit.
            "PYTHONPATH": ":".join(["external/" + t for t in transitive_imports.to_list()]),
        },
        mnemonic = _MNEMONIC,
        progress_message = "[mypy] Type-checking %s" % ctx.label,
    )

    return [
        mypy_info(cache_map_outputs, deps),
        OutputGroupInfo(_validation = depset(cache_map_outputs)),
    ]

# buildifier: disable=function-docstring
def _mypy_aspect_impl(_, ctx):
    if ctx.rule.kind not in ["py_binary", "py_library", "py_test"] or ctx.label.workspace_root.startswith("external"):
        return []

    return mypy_action(ctx, ctx.executable._mypy, ctx.rule.files.srcs, ctx.rule.attr.deps, ctx.files._config_files)

def mypy_aspect(binary, configs):
    """A factory function to create a linter aspect.

    Attrs:
        binary: a mypy executable
        configs: mypy config file(s) such as mypy.ini or pyproject.toml, see
            https://mypy.readthedocs.io/en/stable/config_file.html#config-file
    """
    return aspect(
        implementation = _mypy_aspect_impl,
        # Edges we need to walk up the graph from the selected targets.
        # Needed for linters that need semantic information like transitive type declarations.
        attr_aspects = ["deps"],
        attrs = {
            "_mypy": attr.label(
                default = binary,
                executable = True,
                cfg = "exec",
            ),
            "_config_files": attr.label_list(
                default = configs,
                allow_files = True,
            ),
            "rules_lint_verbose": attr.bool(default = False),
        },
    )
