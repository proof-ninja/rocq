public class DriverMagicApply {
  static int natToInt(java_magic_apply.nat n) {
    int i = 0;
    while (n instanceof java_magic_apply.S) {
      i++;
      n = ((java_magic_apply.S) n).S0;
    }
    return i;
  }

  public static void main(String[] args) {
    int shown = natToInt(java_magic_apply.apply_dep_fn);
    if (shown != 1) {
      throw new AssertionError("apply_dep_fn: expected 1 but got " + shown);
    }
  }
}
