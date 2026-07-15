public class DriverMatchFailure {
  static void assertRotate(Main.color input, Class<?> expected) {
    Main.color actual = Main.rotate.apply(input);
    if (!expected.equals(actual.getClass())) {
      throw new AssertionError("expected " + expected.getName() + " but got " + actual.getClass().getName());
    }
  }

  public static void main(String[] args) {
    assertRotate(new Main.Red(), Main.Green.class);
    assertRotate(new Main.Green(), Main.Blue.class);
    assertRotate(new Main.Blue(), Main.Red.class);

    // A value that fits no constructor of the inductive type must raise the
    // explicit match failure, not an accidental ClassCastException.
    Main.color alien = new Main.color() {};
    try {
      Main.rotate.apply(alien);
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
