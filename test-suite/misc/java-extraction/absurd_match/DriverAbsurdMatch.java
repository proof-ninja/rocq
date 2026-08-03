public class DriverAbsurdMatch {
  public static void main(String[] args) {
    java_absurd_match.result normal = java_absurd_match.from_shape.apply(new java_absurd_match.Leaf());
    if (!java_absurd_match.Ok.class.equals(normal.getClass())) {
      throw new AssertionError("expected Ok but got " + normal.getClass().getName());
    }

    // A [match] on an empty inductive type has no branches; reaching it must
    // raise the explicit absurd-case error, not an accidental exception.
    java_absurd_match.shape absurd = new java_absurd_match.Wrap(new java_absurd_match.empty() {});
    try {
      java_absurd_match.from_shape.apply(absurd);
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
