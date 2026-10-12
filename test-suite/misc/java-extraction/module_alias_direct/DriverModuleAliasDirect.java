public class DriverModuleAliasDirect {
  private static void check(boolean ok, String what) {
    if (!ok) {
      throw new RuntimeException("check failed: " + what);
    }
  }

  public static void main(String[] args) {
    java_module_alias_direct.nat one =
      new java_module_alias_direct.nat.S(new java_module_alias_direct.nat.O());
    java_module_alias_direct.point p =
      new java_module_alias_direct.point.P(one, new java_module_alias_direct.nat.O());
    check(p instanceof java_module_alias_direct.point.P, "P constructs a point");
    java_module_alias_direct.rec r =
      new java_module_alias_direct.rec.MkRec(one, one);
    check(r instanceof java_module_alias_direct.rec.MkRec, "MkRec constructs a rec");
    java_module_alias_direct.float_class c = new java_module_alias_direct.float_class.NaN();
    check(c instanceof java_module_alias_direct.float_class.NaN, "NaN constructs a float_class");
    System.out.println("module_alias_direct: OK");
  }
}
