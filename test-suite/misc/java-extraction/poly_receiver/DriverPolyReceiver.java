public class DriverPolyReceiver {
  static java_poly_receiver.nat intToNat(int n) {
    java_poly_receiver.nat r = new java_poly_receiver.O();
    for (int i = 0; i < n; i++) {
      r = new java_poly_receiver.S(r);
    }
    return r;
  }

  static int natToInt(java_poly_receiver.nat n) {
    int i = 0;
    while (n instanceof java_poly_receiver.S) {
      i++;
      n = ((java_poly_receiver.S) n).S0;
    }
    return i;
  }

  static void check(String name, int expected, java_poly_receiver.nat actual) {
    int shown = natToInt(actual);
    if (expected != shown) {
      throw new AssertionError(name + ": expected " + expected + " but got " + shown);
    }
  }

  public static void main(String[] args) {
    check("result", 2, java_poly_receiver.result);
    check("apply_through_id", 5,
        java_poly_receiver.apply_through_id
            .apply(n -> new java_poly_receiver.S(n))
            .apply(intToNat(3)));
  }
}
