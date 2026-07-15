public class DriverAbsurdMatch {
  public static void main(String[] args) {
    Main.result normal = Main.from_shape.apply(new Main.Leaf());
    if (!Main.Ok.class.equals(normal.getClass())) {
      throw new AssertionError("expected Ok but got " + normal.getClass().getName());
    }

    // A [match] on an empty inductive type has no branches; reaching it must
    // raise the explicit absurd-case error, not an accidental exception.
    Main.shape absurd = new Main.Wrap(new Main.empty() {});
    try {
      Main.from_shape.apply(absurd);
      throw new AssertionError("expected an absurd-case failure but from_shape returned normally");
    } catch (RuntimeException e) {
      if (!RuntimeException.class.equals(e.getClass())) {
        throw new AssertionError("expected a plain RuntimeException but got " + e.getClass().getName(), e);
      }
      if (!"absurd case".equals(e.getMessage())) {
        throw new AssertionError("unexpected absurd-case message: " + e.getMessage(), e);
      }
    }
  }
}
