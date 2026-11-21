public class DriverLocalMutualFix {
  static java_local_mutual_fix.nat intToNat(int n) {
    java_local_mutual_fix.nat r = new java_local_mutual_fix.nat.O();
    for (int i = 0; i < n; i++) {
      r = new java_local_mutual_fix.nat.S(r);
    }
    return r;
  }

  static int natToInt(java_local_mutual_fix.nat n) {
    int i = 0;
    while (n instanceof java_local_mutual_fix.nat.S) {
      i++;
      n = ((java_local_mutual_fix.nat.S) n).S0;
    }
    return i;
  }

  static java_local_mutual_fix.bool bool(boolean b) {
    return b ? new java_local_mutual_fix.bool.True() : new java_local_mutual_fix.bool.False();
  }

  static void check(String what, int expected, java_local_mutual_fix.nat actual) {
    int got = natToInt(actual);
    if (got != expected) {
      throw new AssertionError(what + ": expected " + expected + " but got " + got);
    }
  }

  static void check(String what, boolean expected, java_local_mutual_fix.bool actual) {
    boolean got = actual instanceof java_local_mutual_fix.bool.True;
    if (got != expected) {
      throw new AssertionError(what + ": expected " + expected + " but got " + got);
    }
  }

  public static void main(String[] args) {
    // Computed by [Compute] on the Rocq definitions.
    for (int n = 0; n < 8; n++) {
      boolean ev = n % 2 == 0;
      check("even true " + n, ev, java_local_mutual_fix.even.apply(bool(true)).apply(intToNat(n)));
      check("even false " + n, !ev, java_local_mutual_fix.even.apply(bool(false)).apply(intToNat(n)));
      check("odd true " + n, !ev, java_local_mutual_fix.odd.apply(bool(true)).apply(intToNat(n)));
      check("odd false " + n, ev, java_local_mutual_fix.odd.apply(bool(false)).apply(intToNat(n)));
    }
    // Rows: n, f k n 1, g k n, h k true n 1, h k false n 1.
    int[][] k1 = {
      {0, 2, 1, 1, 1}, {1, 3, 1, 4, 2}, {2, 4, 1, 5, 3}, {3, 5, 0, 6, 4},
      {4, 6, 1, 7, 4}, {5, 7, 0, 8, 5}, {6, 8, 1, 9, 5}, {7, 9, 0, 10, 6},
    };
    int[][] k2 = {
      {0, 3, 1, 1, 1}, {1, 4, 1, 5, 2}, {2, 5, 0, 6, 3}, {3, 6, 1, 7, 3},
      {4, 7, 0, 8, 4}, {5, 8, 1, 9, 4}, {6, 9, 0, 10, 5}, {7, 10, 1, 11, 5},
    };
    int[][][] tables = {k1, k2};
    for (int t = 0; t < 2; t++) {
      java_local_mutual_fix.nat k = intToNat(t + 1);
      for (int[] row : tables[t]) {
        java_local_mutual_fix.nat n = intToNat(row[0]);
        java_local_mutual_fix.nat one = intToNat(1);
        String at = " k=" + (t + 1) + " n=" + row[0];
        check("f" + at, row[1], java_local_mutual_fix.f.apply(k).apply(n).apply(one));
        check("g" + at, row[2] == 1, java_local_mutual_fix.g.apply(k).apply(n));
        check("h true" + at, row[3], java_local_mutual_fix.h.apply(k).apply(bool(true)).apply(n).apply(one));
        check("h false" + at, row[4], java_local_mutual_fix.h.apply(k).apply(bool(false)).apply(n).apply(one));
      }
    }
    int[] four = {3, 1, 4, 8, 7, 11, 10, 14};
    int[] fourD = {6, 5, 9, 8, 12, 11, 15, 14};
    int[] top1 = {0, 0, 0, 2, 0, 4, 0, 6};
    for (int n = 0; n < 8; n++) {
      check("four 1 2 " + n, four[n],
          java_local_mutual_fix.four.apply(intToNat(1)).apply(intToNat(2)).apply(intToNat(n)));
      check("four_d 1 2 " + n + " 3", fourD[n],
          java_local_mutual_fix.four_d.apply(intToNat(1)).apply(intToNat(2)).apply(intToNat(n))
              .apply(intToNat(3)));
      check("top1 " + n, top1[n], java_local_mutual_fix.top1.apply(intToNat(n)));
    }
    System.out.println("local_mutual_fix: OK");
  }
}
