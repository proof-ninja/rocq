public class DriverPrimeNames {
  static void check(String name, boolean ok) {
    if (!ok) {
      throw new AssertionError(name);
    }
  }

  static int toInt(java_prime_names.nat n) {
    int i = 0;
    while (n instanceof java_prime_names.S) {
      n = ((java_prime_names.S) n).S0;
      i++;
    }
    return i;
  }

  public static void main(String[] args) {
    java_prime_names.nat one = new java_prime_names.S(new java_prime_names.O());

    // build' 1 = C' 2
    java_prime_names.t$ x = java_prime_names.build$.apply(one);
    check("build' constructs C'", x instanceof java_prime_names.C$);
    check("build' applies succ'", toInt(((java_prime_names.C$) x).C$0) == 2);

    // unwrap' (C' 2) = 2, unwrap' D' = 0
    check("unwrap' matches C'", toInt(java_prime_names.unwrap$.apply(x)) == 2);
    check("unwrap' matches D'",
        toInt(java_prime_names.unwrap$.apply(new java_prime_names.D$())) == 0);
  }
}
