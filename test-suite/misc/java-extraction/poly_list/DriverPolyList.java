public class DriverPolyList {
  static java_poly_list.nat intToNat(int n) {
    java_poly_list.nat r = new java_poly_list.O();
    for (int i = 0; i < n; i++) {
      r = new java_poly_list.S(r);
    }
    return r;
  }

  static int natToInt(java_poly_list.nat n) {
    int i = 0;
    while (n instanceof java_poly_list.S) {
      i++;
      n = ((java_poly_list.S) n).S0;
    }
    return i;
  }

  static java_poly_list.list build(int... xs) {
    java_poly_list.list l = new java_poly_list.Nil();
    for (int i = xs.length - 1; i >= 0; i--) {
      l = new java_poly_list.Cons(intToNat(xs[i]), l);
    }
    return l;
  }

  // The list is erased: Cons0 is declared Object, so reading an element
  // back at type nat is the caller's (checked) cast.
  static String show(java_poly_list.list l) {
    StringBuilder sb = new StringBuilder("[");
    boolean first = true;
    while (l instanceof java_poly_list.Cons) {
      java_poly_list.Cons c = (java_poly_list.Cons) l;
      if (!first) {
        sb.append("; ");
      }
      sb.append(natToInt((java_poly_list.nat) c.Cons0));
      first = false;
      l = c.Cons1;
    }
    sb.append("]");
    return sb.toString();
  }

  static void assertReverse(String expected, int... xs) {
    java_poly_list.list actual = java_poly_list.reverse_nats.apply(build(xs));
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
