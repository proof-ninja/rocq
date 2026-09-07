public class DriverMagicCons {
  static int natToInt(java_magic_cons.nat n) {
    int i = 0;
    while (n instanceof java_magic_cons.S) {
      i++;
      n = ((java_magic_cons.S) n).S0;
    }
    return i;
  }

  public static void main(String[] args) {
    int shown = natToInt(java_magic_cons.use_dep);
    if (shown != 1) {
      throw new AssertionError("use_dep: expected 1 but got " + shown);
    }
  }
}
