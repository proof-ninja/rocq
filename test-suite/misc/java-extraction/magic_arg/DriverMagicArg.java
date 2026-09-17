public class DriverMagicArg {
  static int natToInt(java_magic_arg.nat n) {
    int i = 0;
    while (n instanceof java_magic_arg.S) {
      i++;
      n = ((java_magic_arg.S) n).S0;
    }
    return i;
  }

  public static void main(String[] args) {
    int shown = natToInt(java_magic_arg.result);
    if (shown != 1) {
      throw new AssertionError("result: expected 1 but got " + shown);
    }
  }
}
