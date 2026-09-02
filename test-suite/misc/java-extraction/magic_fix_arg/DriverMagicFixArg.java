public class DriverMagicFixArg {
  static int natToInt(java_magic_fix_arg.nat n) {
    int i = 0;
    while (n instanceof java_magic_fix_arg.S) {
      i++;
      n = ((java_magic_fix_arg.S) n).S0;
    }
    return i;
  }

  public static void main(String[] args) {
    int shown = natToInt(java_magic_fix_arg.result);
    if (shown != 2) {
      throw new AssertionError("result: expected 2 but got " + shown);
    }
  }
}
