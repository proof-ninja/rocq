public class DriverRecord {
  static java_record.nat intToNat(int n) {
    java_record.nat r = new java_record.O();
    for (int i = 0; i < n; i++) {
      r = new java_record.S(r);
    }
    return r;
  }

  static int natToInt(java_record.nat n) {
    int i = 0;
    while (n instanceof java_record.S) {
      i++;
      n = ((java_record.S) n).S0;
    }
    return i;
  }

  static void check(String name, int expected, java_record.nat actual) {
    int shown = natToInt(actual);
    if (expected != shown) {
      throw new AssertionError(name + ": expected " + expected + " but got " + shown);
    }
  }

  public static void main(String[] args) {
    // origin = MkPoint O O
    check("origin px", 0, java_record.getx.apply(java_record.origin));
    check("origin py", 0, java_record.gety.apply(java_record.origin));

    java_record.point p = new java_record.MkPoint(intToNat(1), intToNat(2));
    check("getx", 1, java_record.getx.apply(p));
    check("gety", 2, java_record.gety.apply(p));

    // swap (1, 2) = (2, 1)
    java_record.point q = java_record.swap.apply(p);
    check("swap px", 2, java_record.getx.apply(q));
    check("swap py", 1, java_record.gety.apply(q));

    // bump (1, 2) = (2, 2)
    java_record.point r = java_record.bump.apply(p);
    check("bump px", 2, java_record.getx.apply(r));
    check("bump py", 2, java_record.gety.apply(r));

    // apply_tagged mk_inc 4 = 5 (mk_inc's op is S)
    check("apply_tagged", 5,
        java_record.apply_tagged.apply(java_record.mk_inc).apply(intToNat(4)));

    // mk_bounded = MkBounded O IsZero (S O): the Prop field is erased and
    // the remaining fields are renumbered contiguously on both sides.
    check("bounded blo", 0, java_record.get_blo.apply(java_record.mk_bounded));
    check("bounded bhi", 1, java_record.get_bhi.apply(java_record.mk_bounded));

    // pair_sum (MkPair 3 4) = 7: reads Object-erased fields, so the
    // inserted casts must hold up at runtime.
    java_record.pair pr = java_record.mk_nat_pair.apply(intToNat(3)).apply(intToNat(4));
    check("pair_sum", 7, java_record.pair_sum.apply(pr));

    // Primitive projections extract through the same positional scheme.
    java_record.ppoint pp = java_record.mk_ppoint.apply(intToNat(2)).apply(intToNat(5));
    check("ppoint ppx", 2, java_record.get_ppx.apply(pp));
    check("ppoint ppy", 5, java_record.get_ppy.apply(pp));
  }
}
