public class DriverTypeAlias {
  static java_type_alias.nat intToNat(int n) {
    java_type_alias.nat r = new java_type_alias.O();
    for (int i = 0; i < n; i++) {
      r = new java_type_alias.S(r);
    }
    return r;
  }

  static int natToInt(java_type_alias.nat n) {
    int i = 0;
    while (n instanceof java_type_alias.S) {
      i++;
      n = ((java_type_alias.S) n).S0;
    }
    return i;
  }

  static void check(String name, int expected, java_type_alias.nat actual) {
    int shown = natToInt(actual);
    if (expected != shown) {
      throw new AssertionError(name + ": expected " + expected + " but got " + shown);
    }
  }

  public static void main(String[] args) {
    // singleton 3 = [3]
    java_type_alias.list s = java_type_alias.singleton.apply(intToNat(3));
    check("singleton head", 3, (java_type_alias.nat) ((java_type_alias.Cons) s).Cons0);

    // twice S 2 = 4
    check("twice", 4,
        java_type_alias.twice.apply(n -> new java_type_alias.S(n)).apply(intToNat(2)));

    // wrap 1 = [[1]]
    java_type_alias.list w = java_type_alias.wrap.apply(intToNat(1));
    java_type_alias.list inner = (java_type_alias.list) ((java_type_alias.Cons) w).Cons0;
    check("wrap inner head", 1, (java_type_alias.nat) ((java_type_alias.Cons) inner).Cons0);

    // second 1 = [2]
    java_type_alias.list t = java_type_alias.second.apply(intToNat(1));
    check("second head", 2, (java_type_alias.nat) ((java_type_alias.Cons) t).Cons0);

    // unbox (Wrap S) 1 = 2
    check("unbox", 2,
        java_type_alias.unbox.apply(new java_type_alias.Wrap(n -> new java_type_alias.S(n)))
            .apply(intToNat(1)));

    // apply_head (singleton_op S) 0 = 1
    check("apply_head", 1,
        java_type_alias.apply_head
            .apply(java_type_alias.singleton_op.apply(n -> new java_type_alias.S(n)))
            .apply(intToNat(0)));

    // unbox Nought 3 = 3
    check("unbox nought", 3,
        java_type_alias.unbox.apply(new java_type_alias.Nought()).apply(intToNat(3)));
  }
}
