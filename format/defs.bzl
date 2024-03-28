"""Produce a multi-formatter that aggregates formatters.

Some formatter tools are automatically provided by default in rules_lint.
These are listed as defaults in the API docs below.

Other formatter binaries may be declared in your repository.
You can test that they work by running them directly with `bazel run`.

For example, to add prettier, your `BUILD.bazel` file should contain:

```
load("@npm//:prettier/package_json.bzl", prettier = "bin")

prettier.prettier_binary(
    name = "prettier",
    # Allow the binary to be run outside bazel
    env = {"BAZEL_BINDIR": "."},
)
```

and you can test it with `bazel run //path/to:prettier -- --help`.

Then you can register it with `format_multirun`:

```
load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

format_multirun(
    name = "format",
    javascript = ":prettier",
)
```
"""

load("@aspect_bazel_lib//lib:lists.bzl", "unique")
load("@rules_multirun//:defs.bzl", "command", "multirun")
load("//format/private:formatter_binary.bzl", "CHECK_FLAGS", "DEFAULT_TOOL_LABELS", "FIX_FLAGS", "TOOLS", "to_attribute_name")

def _format_attr_factory(target_name, lang, toolname, tool_label, mode):
    if mode not in ["check", "fix", "test"]:
        fail("Invalid mode", mode)

    return {
        "name": target_name + (".check" if mode in "check" else ""),
        ("env" if mode == "test" else "environment"): {
            # NB: can't use str(Label(target_name)) here because bzlmod makes it
            # the apparent repository, starts with @@aspect_rules_lint~override
            "FIX_TARGET": "//{}:{}".format(native.package_name(), target_name),
            "tool": "$(rlocationpaths %s)" % tool_label,
            "lang": lang,
            "flags": FIX_FLAGS[toolname] if mode == "fix" else CHECK_FLAGS[toolname],
            "mode": "check" if mode == "test" else mode,
        },
        "data": [tool_label],
    }

def format_multirun(name, jobs = 4, **kwargs):
    """Create a multirun binary for the given formatters.

    Intended to be used with `bazel run` to update source files in-place.
    To check formatting with `bazel test`, see [format_test](#format_test).

    Also produces a target `[name].check` which does not edit files, rather it exits non-zero
    if any sources require formatting.

    Tools are provided by default for some languages.
    These come from the `@multitool` repo.
    Under --enable_bzlmod, rules_lint creates this automatically.
    WORKSPACE users will have to set this up manually. See the release install snippet for an example.

    Set any attribute to `False` to turn off that language altogether, rather than use a default tool.

    Note that `javascript` is a special case which also formats TypeScript, TSX, JSON, CSS, and HTML.

    Args:
        name: name of the resulting target, typically "format"
        jobs: how many language formatters to spawn in parallel, ideally matching how many CPUs are available
        **kwargs: attributes named for each language, providing Label of a tool that formats it
    """
    commands = []

    for lang, toolname, tool_label, target_name in _tools_loop(name, kwargs):
        for mode in ["check", "fix"]:
            command(
                command = "@aspect_rules_lint//format/private:format",
                description = "Formatting {} with {}...".format(lang, toolname),
                **_format_attr_factory(target_name, lang, toolname, tool_label, mode)
            )
        commands.append(target_name)

    # Error checking in case some user keys were unmatched and therefore not pop'ed
    for attr in kwargs.keys():
        fail("""Unknown language "{}". Valid values: {}""".format(attr, [to_attribute_name(lang) for lang in TOOLS.keys()]))

    multirun(
        name = name,
        buffer_output = True,
        commands = commands,
        jobs = jobs,
        keep_going = True,
    )

    multirun(
        name = name + ".check",
        commands = [c + ".check" for c in commands],
        jobs = jobs,
        keep_going = True,
    )

def format_test(name, srcs = None, workspace = None, no_sandbox = False, tags = [], **kwargs):
    """Create test for the given formatters.

    Intended to be used with `bazel test` to verify files are formatted.
    To format with `bazel run`, see [format_multirun](#format_multirun).

    Args:
        name: name of the resulting target, typically "format"
        srcs: list of files to verify formatting. Required when no_sandbox is False.
        workspace: a file in the root directory to verify formatting. Required when no_sandbox is True.
            Typically `//:WORKSPACE` or `//:MODULE.bazel` may be used.
        no_sandbox: Set to True to enable formatting all files in the workspace.
            This mode causes the test to be non-hermetic and it cannot be cached. Read the documentation in /docs/formatting.md.
        tags: tags to apply to generated targets. In 'no_sandbox' mode, `["no-sandbox", "no-cache", "external"]` are added to the tags.
        **kwargs: attributes named for each language, providing Label of a tool that formats it
    """
    if srcs and workspace:
        fail("Cannot provide both 'srcs' and 'workspace' at the same time")
    if not srcs and not workspace:
        fail("One of 'srcs' or 'workspace' must be provided")
    if no_sandbox and not workspace:
        fail("When no_sandbox is True, then the workspace attribute is required")
    if not srcs and not no_sandbox:
        fail("When no_sandbox is False, then the srcs attribute is required")

    test_targets = []
    for lang, toolname, tool_label, target_name in _tools_loop(name, kwargs):
        attrs = _format_attr_factory(target_name, lang, toolname, tool_label, "test")
        if srcs:
            attrs["data"] = [tool_label] + srcs
            attrs["args"] = ["$(location {})".format(i) for i in srcs]
        else:
            attrs["data"] = [tool_label, workspace]
            attrs["env"]["WORKSPACE"] = "$(location {})".format(workspace)

        native.sh_test(
            srcs = ["@aspect_rules_lint//format/private:format.sh"],
            deps = ["@bazel_tools//tools/bash/runfiles"],
            tags = unique(tags + (["no-sandbox", "no-cache", "external"] if workspace else [])),
            **attrs
        )
        test_targets.append(attrs["name"])
    native.test_suite(
        name = name,
        tests = test_targets,
        tags = tags,
    )

def _tools_loop(name, kwargs):
    result = []

    for lang, toolname in TOOLS.items():
        lang_attribute = to_attribute_name(lang)

        # Logic:
        # - if there's no value for this key, the user omitted it, so use our default if we have one
        # - if there is a value, and it's False, then skip this language
        #   (and make sure we don't eagerly reference @multitool in case it isn't defined)
        # - otherwise use the user-supplied value
        tool_label = False
        if lang_attribute in kwargs.keys():
            tool_label = kwargs.pop(lang_attribute)
        elif lang in DEFAULT_TOOL_LABELS.keys():
            tool_label = Label(DEFAULT_TOOL_LABELS[lang])
        if not tool_label:
            continue

        target_name = "_".join([name, lang.replace(" ", "_"), "with", toolname])

        result.append((lang, toolname, tool_label, target_name))

    # Error checking in case some user keys were unmatched and therefore not pop'ed
    for attr in kwargs.keys():
        fail("""Unknown language "{}". Valid values: {}""".format(attr, [to_attribute_name(lang) for lang in TOOLS.keys()]))

    return result
