public class DriverLocalFixObjectTarget {
  static java_local_fix_object_target.nat intToNat(int n) {
    java_local_fix_object_target.nat r = new java_local_fix_object_target.nat.O();
    for (int i = 0; i < n; i++) {
      r = new java_local_fix_object_target.nat.S(r);
    }
    return r;
  }

  static int natToInt(Object n) {
    int i = 0;
    while (n instanceof java_local_fix_object_target.nat.S) {
      i++;
      n = ((java_local_fix_object_target.nat.S) n).S0;
    }
    if (!(n instanceof java_local_fix_object_target.nat.O)) {
      throw new AssertionError("not a nat: " + n);
    }
    return i;
  }

  static int posToInt(Object p) {
    int i = 0;
    while (p instanceof java_local_fix_object_target.pos.XO) {
      i++;
      p = ((java_local_fix_object_target.pos.XO) p).XO0;
    }
    if (!(p instanceof java_local_fix_object_target.pos.XH)) {
      throw new AssertionError("not a pos: " + p);
    }
    return i;
  }

  static Object snd(java_local_fix_object_target.prod p) {
    return ((java_local_fix_object_target.prod.Pair) p).Pair1;
  }

  @SuppressWarnings("unchecked")
  static java.util.function.Function<Object, Object> funResult(java_local_fix_object_target.nat n) {
    return (java.util.function.Function<Object, Object>) snd(java_local_fix_object_target.fun_result.apply(n));
  }

  static void check(String what, int expected, int actual) {
    if (actual != expected) {
      throw new AssertionError(what + ": expected " + expected + " but got " + actual);
    }
  }

  // [depth n]: n pairs whose first components are 0 ... 0 1, then 0.
  static void checkDepth(int n) {
    Object v = snd(java_local_fix_object_target.depth.apply(intToNat(n)));
    for (int i = n; i >= 1; i--) {
      java_local_fix_object_target.prod.Pair p = (java_local_fix_object_target.prod.Pair) v;
      check("depth " + n + " at " + i, i == 1 ? 1 : 0, natToInt(p.Pair0));
      v = p.Pair1;
    }
    check("depth " + n + " at 0", 0, natToInt(v));
  }

  public static void main(String[] args) {
    for (int n = 0; n <= 6; n++) {
      java_local_fix_object_target.nat x = intToNat(n);
      check("field " + n, n, posToInt(snd(java_local_fix_object_target.field.apply(x))));
      check("param " + n, n, posToInt(java_local_fix_object_target.param.apply(x)));
      check("scrut " + n, n == 0 ? 0 : 1, natToInt(java_local_fix_object_target.scrut.apply(x)));
      check("twice " + n, 1 << n, natToInt(snd(java_local_fix_object_target.twice.apply(x))));
      check("tail " + n, (n + 1) / 2, natToInt(snd(java_local_fix_object_target.tail.apply(x))));
      check("in_arg " + n, n, natToInt(snd(java_local_fix_object_target.in_arg.apply(x))));
      check("in_body " + n, n * (n + 1) / 2, natToInt(snd(java_local_fix_object_target.in_body.apply(x))));
      check("in_tail " + n, n * (n - 1) / 2, natToInt(snd(java_local_fix_object_target.in_tail.apply(x))));
      check("cps_object " + n, 2 * n, natToInt(snd(java_local_fix_object_target.cps_object.apply(x))));
      check("cps " + n, 2 * n, natToInt(java_local_fix_object_target.cps.apply(x)));
      checkDepth(n);
      check("catch_all " + n, n == 0 ? 2 : 1, natToInt(java_local_fix_object_target.catch_all.apply(x)));
      check("fun_result " + n, n, natToInt(funResult(x).apply(intToNat(0))));
      check("self_value " + n, n, posToInt(snd(java_local_fix_object_target.self_value.apply(x))));
      check("self_partial " + n, n, posToInt(snd(java_local_fix_object_target.self_partial.apply(x))));
      check("scrut_object " + n, n == 0 ? 0 : 1, natToInt(java_local_fix_object_target.scrut_object.apply(x)));
    }
    System.out.println("local_fix_object_target: OK");
  }
}
