public class DriverAxiom {
  public static void main(String[] args) {
    // An unrealized axiom extracts to a throwing static field initializer, so
    // the first touch of the extracted class fails its static initialization.
    try {
      java_axiom.mystery.getClass();
      throw new AssertionError("expected class initialization to fail but mystery was usable");
    } catch (ExceptionInInitializerError e) {
      Throwable cause = e.getCause();
      if (cause == null || !RuntimeException.class.equals(cause.getClass())) {
        throw new AssertionError("expected a plain RuntimeException cause but got " + cause, e);
      }
      if (!"AXIOM TO BE REALIZED (axiom.mystery)".equals(cause.getMessage())) {
        throw new AssertionError("unexpected axiom message: " + cause.getMessage(), e);
      }
    }
  }
}
