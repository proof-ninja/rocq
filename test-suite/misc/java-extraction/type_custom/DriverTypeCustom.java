public class DriverTypeCustom {
  static void check(String name, long expected, java.math.BigInteger actual) {
    if (!actual.equals(java.math.BigInteger.valueOf(expected))) {
      throw new AssertionError(name + ": expected " + expected + " but got " + actual);
    }
  }

  public static void main(String[] args) {
    check("zero_big", 0, java_type_custom.zero_big);
    check("inc2", 2, java_type_custom.inc2.apply(java_type_custom.zero_big));
    check("inc2b", 4,
        java_type_custom.inc2b.apply(java_type_custom.inc2.apply(java_type_custom.zero_big)));
  }
}
