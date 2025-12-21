// Violation of https://docs.pmd-code.org/latest/pmd_rules_java_errorprone.html#finalizeoverloaded
// Demo of detection:
// bazel run :pmd --run_under="cd $PWD &&" -- -d src -R
// "category/java/errorprone.xml/FinalizeOverloaded"
// src/equals_null.java:6: FinalizeOverloaded:     Finalize methods should not be overloaded
// Error: bazel exited with exit code: 4

// spotbugs result
// M B OS: Foo.readFile() may fail to close stream  At Foo.java:[line 18]
// H D DLS: Dead store to $L1 in Foo.readFile()  At Foo.java:[line 18]
// M X OBL: Foo.readFile() may fail to clean up java.io.InputStream  Obligation to clean up resource
// created at Foo.java:[line 18] is not discharged
public class Foo {

  // SpotBugs violation: Logical errors (NP_NULL_ON_SOME_PATH + DLS_DEAD_STORE)
  public void someMethod(String str) {
    if (str.equals("test")) { // Possible NPE if str is null
      System.out.println("Valid string");
    }

    int a = 5;
    a = 10; // The assignment to 5 is dead (overwritten with 10)
    System.out.println(a);
  }

  // SpotBugs violation: Unused field (URF_UNREAD_FIELD)
  private int unusedField;

  // SpotBugs violation: Resource leak (RCN_RESOURCE_LEAK)
  public void readFile() {
    FileReaderUtil fileReaderUtil = new FileReaderUtil();
    try {
      fileReaderUtil.readFile("somefile.txt");
    } catch (java.io.IOException e) {
      e.printStackTrace();
    }
  }
}

