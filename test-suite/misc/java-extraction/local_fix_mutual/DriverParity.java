public class DriverParity {
  static Main.nat intToNat(int n) {
    Main.nat r = new Main.O();
    for (int i = 0; i < n; i++) {
      r = new Main.S(r);
    }
    return r;
  }

  static String show(Main.parity p) {
    if (p instanceof Main.Even) {
      return "Even";
    }
    if (p instanceof Main.Odd) {
      return "Odd";
    }
    throw new AssertionError("unknown parity value");
  }

  static void assertParity(String expected, Main.parity actual) {
    String actualShown = show(actual);
    if (!expected.equals(actualShown)) {
      throw new AssertionError("expected " + expected + " but got " + actualShown);
    }
  }

  static void assertSuccAgrees(int n) {
    String expected = show(Main.parity_of.apply(intToNat(n + 1)));
    String actual = show(Main.parity_of_succ.apply(intToNat(n)));
    if (!expected.equals(actual)) {
      throw new AssertionError("expected parity_of_succ " + n + " to be " + expected + " but got " + actual);
    }
  }

  public static void main(String[] args) {
    assertParity("Even", Main.parity_of.apply(intToNat(0)));
    assertParity("Odd", Main.parity_of.apply(intToNat(5)));
    assertSuccAgrees(0);
    assertSuccAgrees(1);
    assertSuccAgrees(2);
    assertSuccAgrees(3);
    assertSuccAgrees(4);
  }
}
