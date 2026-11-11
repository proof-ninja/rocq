public class DriverLocalFixArgCast {
  static java_local_fix_arg_cast.nat intToNat(int n) {
    java_local_fix_arg_cast.nat r = new java_local_fix_arg_cast.nat.O();
    for (int i = 0; i < n; i++) {
      r = new java_local_fix_arg_cast.nat.S(r);
    }
    return r;
  }

  static int natToInt(java_local_fix_arg_cast.nat n) {
    int i = 0;
    while (n instanceof java_local_fix_arg_cast.nat.S) {
      i++;
      n = ((java_local_fix_arg_cast.nat.S) n).S0;
    }
    return i;
  }

  static java_local_fix_arg_cast.duo duo(int a, int b) {
    return new java_local_fix_arg_cast.duo.Duo(intToNat(a), intToNat(b));
  }

  static void check(String what, int expected, java_local_fix_arg_cast.nat actual) {
    int got = natToInt(actual);
    if (got != expected) {
      throw new AssertionError(what + ": expected " + expected + " but got " + got);
    }
  }

  public static void main(String[] args) {
    check("duo_sum 2 3", 5, java_local_fix_arg_cast.duo_sum.apply(duo(2, 3)));
    check("duo_sum 0 4", 4, java_local_fix_arg_cast.duo_sum.apply(duo(0, 4)));
    check("duo_sum' 2 3", 5, java_local_fix_arg_cast.duo_sum$.apply(duo(2, 3)));
    check("duo_mix 2 3", 10, java_local_fix_arg_cast.duo_mix.apply(duo(2, 3)));
    check("duo_mix 0 1", 2, java_local_fix_arg_cast.duo_mix.apply(duo(0, 1)));
    check("escape 3", 3, java_local_fix_arg_cast.escape.apply(intToNat(3)));
    check("escape 0", 0, java_local_fix_arg_cast.escape.apply(intToNat(0)));
  }
}
