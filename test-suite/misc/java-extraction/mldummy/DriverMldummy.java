import java.util.function.Function;

public class DriverMldummy {
  public static void main(String[] args) {
    // Erased logical content becomes the benign dummy value: touching it must
    // not throw (unlike an unrealized axiom), and it must survive being
    // treated as a function, since extracted code may pass it around and
    // apply it.
    if (Main.tt_prop == null) {
      throw new AssertionError("expected tt_prop to be a benign value but was null");
    }
    if (Main.both == null) {
      throw new AssertionError("expected both to be a benign value but was null");
    }
    @SuppressWarnings("unchecked")
    Function<Object, Object> f = (Function<Object, Object>) Main.tt_prop;
    if (f.apply(null) != Main.tt_prop) {
      throw new AssertionError("expected the dummy to be self-applicable");
    }
  }
}
