package src;

// Unused imports are suppressed in suppressions.xml, so this should not raise issue.

public class Bar {
  // Max line length set to 20, so this should raise issue.
  protected void finalize(int a) {}
}
