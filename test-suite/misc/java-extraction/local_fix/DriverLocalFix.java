public class DriverLocalFix {
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

  static void assertList(String expected, Main.natlist actual) {
    String actualShown = show(actual);
    if (!expected.equals(actualShown)) {
      throw new AssertionError("expected " + expected + " but got " + actualShown);
    }
  }

  public static void main(String[] args) {
    assertList("[3; 2; 1]", Main.rev_acc.apply(build(1, 2, 3)).apply(new Main.Nil()));
    assertList("[]", Main.rev_acc.apply(build()).apply(new Main.Nil()));
    assertList("[4; 5; 6]", Main.rev_pair.apply(build(4, 5, 6)));

    // One argument applied at the call site: fix1. The partial application
    // is evaluated once at class-init time, so it must be reusable.
    assertList("[3; 2; 1]", Main.rev_onto.apply(build(1, 2, 3)));
    assertList("[]", Main.rev_onto.apply(build()));
    assertList("[2; 1]", Main.rev_onto.apply(build(1, 2)));
  }
}
