public class DriverPolyHead {
  static java_poly_head.nat intToNat(int n) {
    java_poly_head.nat r = new java_poly_head.O();
    for (int i = 0; i < n; i++) {
      r = new java_poly_head.S(r);
    }
    return r;
  }

  static int natToInt(java_poly_head.nat n) {
    int i = 0;
    while (n instanceof java_poly_head.S) {
      i++;
      n = ((java_poly_head.S) n).S0;
    }
    return i;
  }

  static java_poly_head.list build(int... xs) {
    java_poly_head.list l = new java_poly_head.Nil();
    for (int i = xs.length - 1; i >= 0; i--) {
      l = new java_poly_head.Cons(intToNat(xs[i]), l);
    }
    return l;
  }

  static void check(String name, int expected, java_poly_head.nat actual) {
    int shown = natToInt(actual);
    if (expected != shown) {
      throw new AssertionError(name + ": expected " + expected + " but got " + shown);
    }
  }

  public static void main(String[] args) {
    check("three", 3, java_poly_head.three);
    check("succ_head", 8, java_poly_head.succ_head.apply(build(7, 1)));
    check("succ_head(nil)", 1, java_poly_head.succ_head.apply(build()));
    check("first_or_zero", 7, java_poly_head.first_or_zero.apply(build(7, 1)));
    check("first_or_zero(nil)", 0, java_poly_head.first_or_zero.apply(build()));
  }
}
