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

load("@rules_multirun//:defs.bzl", "command", "multirun")
load("//format/private:formatter_binary.bzl", "CHECK_FLAGS", "DEFAULT_TOOL_LABELS", "FIX_FLAGS", "TOOLS", "to_attribute_name")

def format_multirun(name, **kwargs):
    """Create a multirun binary for the given formatters.

    Intended to be used with `bazel run` to update source files in-place.

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
        **kwargs: attributes named for each language, providing Label of a tool that formats it
    """
    commands = []

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

        for mode in ["check", "fix"]:
            command(
                name = target_name + (".check" if mode == "check" else ""),
                command = "@aspect_rules_lint//format/private:format",
                description = "Formatting {} with {}...".format(lang, toolname),
                environment = {
                    # NB: can't use str(Label(target_name)) here because bzlmod makes it
                    # the apparent repository, starts with @@aspect_rules_lint~override
                    "FIX_TARGET": "//{}:{}".format(native.package_name(), target_name),
                    "tool": "$(rlocationpaths %s)" % tool_label,
                    "lang": lang,
                    "flags": FIX_FLAGS[toolname] if mode == "fix" else CHECK_FLAGS[toolname],
                    "mode": mode,
                },
                data = [tool_label],
            )
        commands.append(target_name)

    # Error checking in case some user keys were unmatched and therefore not pop'ed
    for attr in kwargs.keys():
        fail("""Unknown language "{}". Valid values: {}""".format(attr, [to_attribute_name(lang) for lang in TOOLS.keys()]))

    multirun(
        name = name,
        buffer_output = True,
        commands = commands,
        # Run up to 4 formatters at the same time. This is an arbitrary choice, based on some idea that 4-core machines are typical.
        jobs = 4,
        keep_going = True,
    )

    multirun(
        name = name + ".check",
        commands = [c + ".check" for c in commands],
    )
