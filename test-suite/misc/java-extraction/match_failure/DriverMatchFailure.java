public class DriverMatchFailure {
  static void assertRotate(java_match_failure.color input, Class<?> expected) {
    java_match_failure.color actual = java_match_failure.rotate.apply(input);
    if (!expected.equals(actual.getClass())) {
      throw new AssertionError("expected " + expected.getName() + " but got " + actual.getClass().getName());
    }
  }

  public static void main(String[] args) {
    assertRotate(new java_match_failure.Red(), java_match_failure.Green.class);
    assertRotate(new java_match_failure.Green(), java_match_failure.Blue.class);
    assertRotate(new java_match_failure.Blue(), java_match_failure.Red.class);

    // A value that fits no constructor of the inductive type must raise the
    // explicit match failure, not an accidental ClassCastException.
    java_match_failure.color alien = new java_match_failure.color() {};
    try {
      java_match_failure.rotate.apply(alien);
      throw new AssertionError("expected a match failure but rotate returned normally");
    } catch (RuntimeException e) {
      if (!RuntimeException.class.equals(e.getClass())) {
        throw new AssertionError("expected a plain RuntimeException but got " + e.getClass().getName(), e);
      }
      if (!"non-exhaustive match".equals(e.getMessage())) {
        throw new AssertionError("unexpected match failure message: " + e.getMessage(), e);
      }
    }
  }
}
