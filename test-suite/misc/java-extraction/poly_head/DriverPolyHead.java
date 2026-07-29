public class DriverPolyHead {
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

  static Main.list build(int... xs) {
    Main.list l = new Main.Nil();
    for (int i = xs.length - 1; i >= 0; i--) {
      l = new Main.Cons(intToNat(xs[i]), l);
    }
    return l;
  }

  static void check(String name, int expected, Main.nat actual) {
    int shown = natToInt(actual);
    if (expected != shown) {
      throw new AssertionError(name + ": expected " + expected + " but got " + shown);
    }
  }

  public static void main(String[] args) {
    check("three", 3, Main.three);
    check("succ_head", 8, Main.succ_head.apply(build(7, 1)));
    check("succ_head(nil)", 1, Main.succ_head.apply(build()));
    check("first_or_zero", 7, Main.first_or_zero.apply(build(7, 1)));
    check("first_or_zero(nil)", 0, Main.first_or_zero.apply(build()));
  }
}
