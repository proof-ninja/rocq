public class DriverReverse {
  static Main.nat intToNat(int n) {
    Main.nat r = new Main.O();
    for (int i = 0; i < n; i++) {
      r = new Main.S(r);
    }
    return r;
  }

  static int natToInt(Main.nat n) {
    int i = 0;
    while (n instanceof Main.S) {
      i++;
      n = ((Main.S) n).S0;
    }
    return i;
  }

  static Main.natlist build(int... xs) {
    Main.natlist l = new Main.Nil();
    for (int i = xs.length - 1; i >= 0; i--) {
      l = new Main.Cons(intToNat(xs[i]), l);
    }
    return l;
  }

  static String show(Main.natlist l) {
    StringBuilder sb = new StringBuilder("[");
    boolean first = true;
    while (l instanceof Main.Cons) {
      Main.Cons c = (Main.Cons) l;
      if (!first) {
        sb.append("; ");
      }
      sb.append(natToInt(c.Cons0));
      first = false;
      l = c.Cons1;
    }
    sb.append("]");
    return sb.toString();
  }

  static void assertReverse(String expected, int... xs) {
    Main.natlist actual = Main.reverse.apply(build(xs));
    String actualShown = show(actual);
    if (!expected.equals(actualShown)) {
      throw new AssertionError("expected " + expected + " but got " + actualShown);
    }
  }

  public static void main(String[] args) {
    assertReverse("[]");
    assertReverse("[42]", 42);
    assertReverse("[5; 4; 3; 2; 1]", 1, 2, 3, 4, 5);
    assertReverse("[7; 7; 7]", 7, 7, 7);
  }
}
