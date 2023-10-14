// Violation of https://docs.pmd-code.org/latest/pmd_rules_java_errorprone.html#finalizeoverloaded
// Demo of detection:
// bazel run :pmd --run_under="cd $PWD &&" -- -d src -R
// "category/java/errorprone.xml/FinalizeOverloaded"
// src/equals_null.java:6: FinalizeOverloaded:     Finalize methods should not be overloaded
// Error: bazel exited with exit code: 4
public class Foo {
  // this is confusing and probably a bug
  protected void finalize(int a) {}
}
