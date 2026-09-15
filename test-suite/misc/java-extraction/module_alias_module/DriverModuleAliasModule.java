public class DriverModuleAliasModule {
  public static void main(String[] args) {
    java_module_alias_module.float_class c = new java_module_alias_module.NaN();
    if (!(c instanceof java_module_alias_module.NaN)) {
      throw new RuntimeException("check failed: NaN constructs a float_class");
    }
    System.out.println("module_alias_module: OK");
  }
}
