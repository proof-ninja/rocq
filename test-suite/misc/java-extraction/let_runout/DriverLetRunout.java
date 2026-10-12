public class DriverLetRunout {
  static void check(String name, boolean ok) {
    if (!ok) {
      throw new AssertionError(name);
    }
  }

  static int toInt(java_let_runout.nat n) {
    int i = 0;
    while (n instanceof java_let_runout.nat.S) {
      n = ((java_let_runout.nat.S) n).S0;
      i++;
    }
    return i;
  }

  public static void main(String[] args) {
    java_let_runout.nat two =
        new java_let_runout.nat.S(new java_let_runout.nat.S(new java_let_runout.nat.O()));
    java.util.function.Function<java_let_runout.nat, java_let_runout.nat> succ =
        n -> new java_let_runout.nat.S(n);

    // let_runout S 2 = add 3 3 = 6
    check("parameter position", toInt(java_let_runout.let_runout.apply(succ).apply(two)) == 6);
    // let_runout_cons S 2 = S 3 = 4
    check("constructor field", toInt(java_let_runout.let_runout_cons.apply(succ).apply(two)) == 4);
    // let_runout_poly S 2 = idf 3 = 3
    check("Object position", toInt(java_let_runout.let_runout_poly.apply(succ).apply(two)) == 3);
    // let_runout_fun S 2 = S (S 2) = 4
    check("bound function", toInt(java_let_runout.let_runout_fun.apply(succ).apply(two)) == 4);
    // arg_runout S 2 = S 3 = 4
    check("direct argument", toInt(java_let_runout.arg_runout.apply(succ).apply(two)) == 4);
  }
}
