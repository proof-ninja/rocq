public class DriverModuleAlias {
  static java_module_alias.nat intToNat(int n) {
    java_module_alias.nat r = new java_module_alias.O();
    for (int i = 0; i < n; i++) {
      r = new java_module_alias.S(r);
    }
    return r;
  }

  static int natToInt(java_module_alias.nat n) {
    int i = 0;
    while (n instanceof java_module_alias.S) {
      i++;
      n = ((java_module_alias.S) n).S0;
    }
    return i;
  }

  static void check(String name, int expected, java_module_alias.nat actual) {
    int shown = natToInt(actual);
    if (expected != shown) {
      throw new AssertionError(name + ": expected " + expected + " but got " + shown);
    }
  }

  public static void main(String[] args) {
    // cross = snd_of (M.P O (S O)) = 1
    check("cross", 1, java_module_alias.cross);

    // A value built through the canonical name flows through the alias-typed
    // function and back: fst_of (back (P 3 4)) = 3.
    java_module_alias.point p = new java_module_alias.P(intToNat(3), intToNat(4));
    check("fst_of back", 3, java_module_alias.fst_of.apply(java_module_alias.back.apply(p)));

    // rec_sum (mk_rec 2 5) = 7, rec_x (mk_rec 2 5) = 2
    java_module_alias.rec r = java_module_alias.mk_rec.apply(intToNat(2)).apply(intToNat(5));
    check("rec_sum", 7, java_module_alias.rec_sum.apply(r));
    check("rec_x", 2, java_module_alias.rec_x.apply(r));

    // two_digits = digits (xO xH) = 2; the library inductive is declared
    // once, under its canonical name.
    check("two_digits", 2, java_module_alias.two_digits);
    java_module_alias.positive five =
        new java_module_alias.XI(new java_module_alias.XO(new java_module_alias.XH()));
    check("digits", 3, java_module_alias.digits.apply(five));
  }
}
