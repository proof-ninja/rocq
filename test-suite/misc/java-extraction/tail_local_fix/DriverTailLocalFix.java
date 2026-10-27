public class DriverTailLocalFix {
  static void check(String name, boolean ok) {
    if (!ok) {
      throw new AssertionError(name);
    }
  }

  // Deep enough to overflow the default Java stack without the loop.
  static final int DEEP = 200000;

  static int toInt(java_tail_local_fix.nat n) {
    int c = 0;
    while (n instanceof java_tail_local_fix.nat.S s) {
      n = s.S0;
      c++;
    }
    return c;
  }

  static java_tail_local_fix.natlist list(int k, java_tail_local_fix.nat x) {
    java_tail_local_fix.natlist l = new java_tail_local_fix.natlist.Nil();
    for (int i = 0; i < k; i++) {
      l = new java_tail_local_fix.natlist.Cons(x, l);
    }
    return l;
  }

  public static void main(String[] args) {
    java_tail_local_fix.nat zero = new java_tail_local_fix.nat.O();
    java_tail_local_fix.nat one = new java_tail_local_fix.nat.S(zero);

    check("length", toInt(java_tail_local_fix.length.apply(list(DEEP, zero))) == DEEP);
    check("count_zeros", toInt(java_tail_local_fix.count_zeros.apply(list(DEEP, zero))) == DEEP);
    check("count_zeros ones", toInt(java_tail_local_fix.count_zeros.apply(list(5, one))) == 0);
    java_tail_local_fix.natlist r = java_tail_local_fix.rev_onto.apply(list(3, zero));
    check("rev_onto", r instanceof java_tail_local_fix.natlist.Cons);
  }
}
