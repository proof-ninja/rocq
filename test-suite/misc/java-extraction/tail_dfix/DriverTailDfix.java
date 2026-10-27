public class DriverTailDfix {
  static void check(String name, boolean ok) {
    if (!ok) {
      throw new AssertionError(name);
    }
  }

  // Deep enough to overflow the default Java stack without the loop.
  static final int DEEP = 200000;

  static java_tail_dfix.nat nat(int n) {
    java_tail_dfix.nat r = new java_tail_dfix.nat.O();
    for (int i = 0; i < n; i++) {
      r = new java_tail_dfix.nat.S(r);
    }
    return r;
  }

  static int toInt(java_tail_dfix.nat n) {
    int c = 0;
    while (n instanceof java_tail_dfix.nat.S s) {
      n = s.S0;
      c++;
    }
    return c;
  }

  // [k] copies of [x]
  static java_tail_dfix.natlist list(int k, java_tail_dfix.nat x) {
    java_tail_dfix.natlist l = new java_tail_dfix.natlist.Nil();
    for (int i = 0; i < k; i++) {
      l = new java_tail_dfix.natlist.Cons(x, l);
    }
    return l;
  }

  static int length(java_tail_dfix.natlist l) {
    int c = 0;
    while (l instanceof java_tail_dfix.natlist.Cons c0) {
      l = c0.Cons1;
      c++;
    }
    return c;
  }

  public static void main(String[] args) {
    java_tail_dfix.natlist deep = list(DEEP, new java_tail_dfix.nat.O());
    java_tail_dfix.natlist nil = new java_tail_dfix.natlist.Nil();

    check("rev_append", length(java_tail_dfix.rev_append.apply(deep).apply(nil)) == DEEP);
    check("length_acc", toInt(java_tail_dfix.length_acc.apply(deep).apply(nat(0))) == DEEP);
    check("mixed tail", toInt(java_tail_dfix.mixed.apply(deep).apply(nat(0))) == DEEP);
    check("mixed non-tail",
        toInt(java_tail_dfix.mixed.apply(list(3, nat(1))).apply(nat(2))) == 5);
    // iter f [_; _; _] x = f (f (f x)) composed as described: 0 + 0 + 1 + 2
    check("iter",
        toInt(java_tail_dfix.iter.apply(y -> new java_tail_dfix.nat.S(y))
            .apply(list(3, nat(0))).apply(nat(0))) == 6);
    check("add_acc", toInt(java_tail_dfix.add_acc.apply(nat(DEEP)).apply(nat(3))) == DEEP + 3);
    check("add", toInt(java_tail_dfix.add.apply(nat(4)).apply(nat(3))) == 7);
  }
}
