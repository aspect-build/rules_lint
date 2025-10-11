<!-- Generated with Stardoc: http://skydoc.bazel.build -->

API for calling declaring a cppcheck lint aspect.

<a id="cppcheck_action"></a>

## cppcheck_action

<pre>
load("@aspect_rules_lint//lint:cppcheck.bzl", "cppcheck_action")

cppcheck_action(<a href="#cppcheck_action-ctx">ctx</a>, <a href="#cppcheck_action-compilation_context">compilation_context</a>, <a href="#cppcheck_action-executable">executable</a>, <a href="#cppcheck_action-srcs">srcs</a>, <a href="#cppcheck_action-stdout">stdout</a>, <a href="#cppcheck_action-exit_code">exit_code</a>, <a href="#cppcheck_action-do_xml">do_xml</a>)
</pre>

Create a Bazel Action that spawns a cppcheck process.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="cppcheck_action-ctx"></a>ctx |  an action context OR aspect context   |  none |
| <a id="cppcheck_action-compilation_context"></a>compilation_context |  from target   |  none |
| <a id="cppcheck_action-executable"></a>executable |  struct with a cppcheck field   |  none |
| <a id="cppcheck_action-srcs"></a>srcs |  file objects to lint   |  none |
| <a id="cppcheck_action-stdout"></a>stdout |  output file containing the stdout or --output-file of cppcheck   |  none |
| <a id="cppcheck_action-exit_code"></a>exit_code |  output file containing the exit code of cppcheck. If None, then fail the build when cppcheck exits non-zero.   |  none |
| <a id="cppcheck_action-do_xml"></a>do_xml |  If true, xml output is generated   |  `False` |


<a id="lint_cppcheck_aspect"></a>

## lint_cppcheck_aspect

<pre>
load("@aspect_rules_lint//lint:cppcheck.bzl", "lint_cppcheck_aspect")

lint_cppcheck_aspect(<a href="#lint_cppcheck_aspect-binary">binary</a>, <a href="#lint_cppcheck_aspect-verbose">verbose</a>)
</pre>

A factory function to create a linter aspect.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lint_cppcheck_aspect-binary"></a>binary |  the cppcheck binary, typically a rule like<br><br><pre><code class="language-starlark">sh_binary(&#10;    name = "cppcheck",&#10;    srcs = [":cppcheck_wrapper.sh"],&#10;)</code></pre> As cppcheck does not support any configuration files so far, all arguments shall be directly implemented in the wrapper script. This file can also directly pass the license file to cppcheck, if needed.<br><br>An example wrapper script could look like this:<br><br><pre><code class="language-bash">#!/bin/bash&#10;&#10;~/.local/bin/cppcheckpremium/cppcheck                 --check-level=exhaustive                 --enable=warning,style,performance,portability,information                 "$@"</code></pre>   |  none |
| <a id="lint_cppcheck_aspect-verbose"></a>verbose |  print debug messages including cppcheck command lines being invoked.   |  `False` |


