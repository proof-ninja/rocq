public class DriverReverse {
  static java_list_reverse.nat intToNat(int n) {
    java_list_reverse.nat r = new java_list_reverse.O();
    for (int i = 0; i < n; i++) {
      r = new java_list_reverse.S(r);
    }
    return r;
  }

  static int natToInt(java_list_reverse.nat n) {
    int i = 0;
    while (n instanceof java_list_reverse.S) {
      i++;
      n = ((java_list_reverse.S) n).S0;
    }
    return i;
  }

  static java_list_reverse.natlist build(int... xs) {
    java_list_reverse.natlist l = new java_list_reverse.Nil();
    for (int i = xs.length - 1; i >= 0; i--) {
      l = new java_list_reverse.Cons(intToNat(xs[i]), l);
    }
    return l;
  }

  static String show(java_list_reverse.natlist l) {
    StringBuilder sb = new StringBuilder("[");
    boolean first = true;
    while (l instanceof java_list_reverse.Cons) {
      java_list_reverse.Cons c = (java_list_reverse.Cons) l;
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
    java_list_reverse.natlist actual = java_list_reverse.reverse.apply(build(xs));
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
