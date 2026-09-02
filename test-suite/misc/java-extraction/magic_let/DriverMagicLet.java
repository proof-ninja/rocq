public class DriverMagicLet {
  static java_magic_let.nat intToNat(int n) {
    java_magic_let.nat r = new java_magic_let.O();
    for (int i = 0; i < n; i++) {
      r = new java_magic_let.S(r);
    }
    return r;
  }

  static int natToInt(java_magic_let.nat n) {
    int i = 0;
    while (n instanceof java_magic_let.S) {
      i++;
      n = ((java_magic_let.S) n).S0;
    }
    return i;
  }

  static void check(String name, int expected, java_magic_let.nat actual) {
    int shown = natToInt(actual);
    if (expected != shown) {
      throw new AssertionError(name + ": expected " + expected + " but got " + shown);
    }
  }

  public static void main(String[] args) {
    check("indirect(0)", 1, java_magic_let.indirect.apply(intToNat(0)));
    check("indirect(2)", 3, java_magic_let.indirect.apply(intToNat(2)));
  }
}
