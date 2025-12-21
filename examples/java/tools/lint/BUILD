load("@rules_java//java:defs.bzl", "java_binary")

package(default_visibility = ["//:__subpackages__"])

java_binary(
    name = "pmd",
    main_class = "net.sourceforge.pmd.cli.PmdCli",
    runtime_deps = ["@net_sourceforge_pmd"],
)

java_binary(
    name = "checkstyle",
    main_class = "com.puppycrawl.tools.checkstyle.Main",
    runtime_deps = ["@com_puppycrawl_tools_checkstyle//jar"],
)

java_binary(
    name = "spotbugs",
    jvm_flags = [
        "--add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED",
        "--add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED",
        "--add-exports jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED",
        "--add-exports jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED",
        "--add-exports jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED",
    ],
    main_class = "edu.umd.cs.findbugs.LaunchAppropriateUI",
    runtime_deps = [
        "@spotbugs//:jar",
    ],
)
