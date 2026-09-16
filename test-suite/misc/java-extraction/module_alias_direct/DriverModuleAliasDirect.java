public class DriverModuleAliasDirect {
  private static void check(boolean ok, String what) {
    if (!ok) {
      throw new RuntimeException("check failed: " + what);
    }
  }

  public static void main(String[] args) {
    java_module_alias_direct.nat one =
      new java_module_alias_direct.S(new java_module_alias_direct.O());
    java_module_alias_direct.point p =
      new java_module_alias_direct.P(one, new java_module_alias_direct.O());
    check(p instanceof java_module_alias_direct.P, "P constructs a point");
    java_module_alias_direct.rec r =
      new java_module_alias_direct.MkRec(one, one);
    check(r instanceof java_module_alias_direct.MkRec, "MkRec constructs a rec");
    java_module_alias_direct.float_class c = new java_module_alias_direct.NaN();
    check(c instanceof java_module_alias_direct.NaN, "NaN constructs a float_class");
    System.out.println("module_alias_direct: OK");
  }
}
