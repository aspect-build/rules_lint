"""Produce a multi-formatter that aggregates formatter tools.

Some formatter tools are built-in to rules_lint and may be installed by [multitool].
These are noted in the attributes for each language in 'languages' below.

Note: Under `--enable_bzlmod`, rules_lint installs multitool automatically.
`WORKSPACE` users must install it manually; see the snippet on the releases page.

Other formatter binaries may be declared in your repository, typically in `tools/format/BUILD.bazel`.
You can test that they work by running them directly, with `bazel run -- //tools/format:some-tool`.
Then use the label `//tools/format:some-tool` as the value of whatever language attribute in `format_multirun`. 
See the example/tools/format/BUILD file in this repo for full examples of declaring formatters.

[multitool]: https://registry.bazel.build/modules/rules_multitool
"""

load("@aspect_bazel_lib//lib:lists.bzl", "unique")
load("@aspect_bazel_lib//lib:utils.bzl", "propagate_common_rule_attributes", "propagate_common_test_rule_attributes")
load("@rules_multirun//:defs.bzl", "command", "multirun")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
load("//format/private:formatter_binary.bzl", "BUILTIN_TOOL_LABELS", "CHECK_FLAGS", "FIX_FLAGS", "TOOLS", "to_attribute_name")

def _format_attr_factory(target_name, lang, toolname, tool_label, mode, disable_git_attribute_checks):
    if mode not in ["check", "fix", "test"]:
        fail("Invalid mode", mode)

    args = []

    # this dict is used to create the attributes both to pass to command() (for
    # format_multirun) and to sh_test() (for format_test, so it has to toggle
    # between different attr names ("env" vs "environment", "args" vs
    # "arguments")
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
            "disable_git_attribute_checks": "true" if disable_git_attribute_checks else "false",
        },
        "data": [tool_label],
        ("args" if mode == "test" else "arguments"): args,
    }

languages = rule(
    implementation = lambda ctx: fail("languages rule is documentation-only; do not call it"),
    doc = """\
Language attributes that may be passed to [format_multirun](#format_multirun) or [format_test](#format_test).

Files with matching extensions from [GitHub Linguist] will be formatted for the given language.

Some languages have dialects:
    - `javascript` includes TypeScript, TSX, and JSON.
    - `css` includes Less and Sass.

**Do not call the `languages` rule directly, it exists only to document the attributes.**

[GitHub Linguist]: https://github.com/github-linguist/linguist/blob/559a6426942abcae16b6d6b328147476432bf6cb/lib/linguist/languages.yml
""",
    attrs = {
        to_attribute_name(key): attr.label(
            doc = "a `{0}` binary, or any other tool that has a matching command-line interface. {1}".format(
                value,
                "Use `@aspect_rules_lint//format:{}` to choose the built-in tool.".format(BUILTIN_TOOL_LABELS[key].split("/")[-1]) if key in BUILTIN_TOOL_LABELS.keys() else "",
            ),
        )
        for key, value in TOOLS.items()
    },
)

def format_multirun(name, jobs = 4, print_command = False, disable_git_attribute_checks = False, **kwargs):
    """Create a [multirun] binary for the given languages.

    Intended to be used with `bazel run` to update source files in-place.

    This macro produces a target named `[name].check` which does not edit files,
    rather it exits non-zero if any sources require formatting.

    To check formatting with `bazel test`, use [format_test](#format_test) instead.

    [multirun]: https://registry.bazel.build/modules/rules_multirun

    Args:
        name: name of the resulting target, typically "format"
        jobs: how many language formatters to spawn in parallel, ideally matching how many CPUs are available
        print_command: whether to print a progress message before calling the formatter of each language.
            Note that a line is printed for a formatter even if no files of that language are to be formatted.
        disable_git_attribute_checks: Set to True to disable honoring .gitattributes filters
        **kwargs: attributes named for each language; see [languages](#languages)
    """
    commands = []

    common_attrs = propagate_common_rule_attributes(kwargs)
    for k in common_attrs.keys():
        kwargs.pop(k)

    for lang, toolname, tool_label, target_name in _tools_loop(name, kwargs):
        for mode in ["check", "fix"]:
            command(
                command = Label("@aspect_rules_lint//format/private:format"),
                description = "Formatting {} with {}...".format(lang, toolname),
                **_format_attr_factory(target_name, lang, toolname, tool_label, mode, disable_git_attribute_checks)
            )
        commands.append(target_name)

    multirun(
        name = name,
        buffer_output = True,
        commands = commands,
        jobs = jobs,
        keep_going = True,
        print_command = print_command,
        **common_attrs
    )

    multirun(
        name = name + ".check",
        commands = [c + ".check" for c in commands],
        jobs = jobs,
        keep_going = True,
        print_command = print_command,
        **common_attrs
    )

def format_test(name, srcs = None, workspace = None, no_sandbox = False, disable_git_attribute_checks = False, tags = [], **kwargs):
    """Create test for the given formatters.

    Intended to be used with `bazel test` to verify files are formatted.
    **This is not recommended**, because it is either non-hermetic or requires listing all source files.

    To format with `bazel run`, see [format_multirun](#format_multirun).

    Args:
        name: name of the resulting target, typically "format"
        srcs: list of files to verify formatting. Required when no_sandbox is False.
        workspace: a file in the root directory to verify formatting. Required when no_sandbox is True.
            Typically `//:WORKSPACE` or `//:MODULE.bazel` may be used.
        no_sandbox: Set to True to enable formatting all files in the workspace.
            This mode causes the test to be non-hermetic and it cannot be cached. Read the documentation in /docs/formatting.md.
        disable_git_attribute_checks: Set to True to disable honoring .gitattributes filters
        tags: tags to apply to generated targets. In 'no_sandbox' mode, `["no-sandbox", "no-cache", "external"]` are added to the tags.
        **kwargs: attributes named for each language; see [languages](#languages)
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
    common_attrs = propagate_common_test_rule_attributes(kwargs)
    for k in common_attrs.keys():
        kwargs.pop(k)

    srcs_label = None
    if srcs:
        srcs_label = name + "_srcs"
        native.filegroup(
            name = srcs_label,
            srcs = srcs,
        )

    for lang, toolname, tool_label, target_name in _tools_loop(name, kwargs):
        attrs = _format_attr_factory(target_name, lang, toolname, tool_label, "test", disable_git_attribute_checks)
        if srcs_label:
            attrs["data"] = [tool_label, srcs_label]
            attrs["args"] = ["$(locations {})".format(srcs_label)]
        else:
            attrs["data"] = [tool_label, workspace]
            attrs["env"]["WORKSPACE"] = "$(location {})".format(workspace)

        sh_test(
            srcs = [Label("@aspect_rules_lint//format/private:format.sh")],
            deps = [Label("@bazel_tools//tools/bash/runfiles")],
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
        if lang_attribute not in kwargs.keys():
            continue

        tool_label = kwargs.pop(lang_attribute)
        target_name = "_".join([name, lang.replace(" ", "_"), "with", toolname])

        result.append((lang, toolname, tool_label, target_name))

    # Error checking in case some user keys were unmatched and therefore not pop'ed
    for attr in kwargs.keys():
        fail("""Unknown language "{}". Valid values: {}""".format(attr, [to_attribute_name(lang) for lang in TOOLS.keys()]))

    return result
