public class DriverLocalFix {
  static java_local_fix.nat intToNat(int n) {
    java_local_fix.nat r = new java_local_fix.O();
    for (int i = 0; i < n; i++) {
      r = new java_local_fix.S(r);
    }
    return r;
  }

  static int natToInt(java_local_fix.nat n) {
    int i = 0;
    while (n instanceof java_local_fix.S) {
      i++;
      n = ((java_local_fix.S) n).S0;
    }
    return i;
  }

  static java_local_fix.natlist build(int... xs) {
    java_local_fix.natlist l = new java_local_fix.Nil();
    for (int i = xs.length - 1; i >= 0; i--) {
      l = new java_local_fix.Cons(intToNat(xs[i]), l);
    }
    return l;
  }

  static String show(java_local_fix.natlist l) {
    StringBuilder sb = new StringBuilder("[");
    boolean first = true;
    while (l instanceof java_local_fix.Cons) {
      java_local_fix.Cons c = (java_local_fix.Cons) l;
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

  static void assertList(String expected, java_local_fix.natlist actual) {
    String actualShown = show(actual);
    if (!expected.equals(actualShown)) {
      throw new AssertionError("expected " + expected + " but got " + actualShown);
    }
  }

  public static void main(String[] args) {
    assertList("[3; 2; 1]", java_local_fix.rev_acc.apply(build(1, 2, 3)).apply(new java_local_fix.Nil()));
    assertList("[]", java_local_fix.rev_acc.apply(build()).apply(new java_local_fix.Nil()));
    assertList("[4; 5; 6]", java_local_fix.rev_pair.apply(build(4, 5, 6)));

    // One argument applied at the call site: fix1. The partial application
    // is evaluated once at class-init time, so it must be reusable.
    assertList("[3; 2; 1]", java_local_fix.rev_onto.apply(build(1, 2, 3)));
    assertList("[]", java_local_fix.rev_onto.apply(build()));
    assertList("[2; 1]", java_local_fix.rev_onto.apply(build(1, 2)));
  }
}
