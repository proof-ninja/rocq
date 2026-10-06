public class DriverConsFunField {
  static void check(String name, boolean ok) {
    if (!ok) {
      throw new AssertionError(name);
    }
  }

  static int toInt(java_cons_fun_field.nat n) {
    int i = 0;
    while (n instanceof java_cons_fun_field.S) {
      n = ((java_cons_fun_field.S) n).S0;
      i++;
    }
    return i;
  }

  public static void main(String[] args) {
    // p_glob = succ O = 1
    check("global function", toInt(java_cons_fun_field.p_glob) == 1);
    // p_lam = (fun x => S x) O = 1
    check("bare lambda", toInt(java_cons_fun_field.p_lam) == 1);
    // p_var = succ O = 1
    check("local variable", toInt(java_cons_fun_field.p_var) == 1);
    // p_app = add 1 1 = 2
    check("partial application", toInt(java_cons_fun_field.p_app) == 2);
    // p_poly = succ O = 1
    check("polymorphic code", toInt(java_cons_fun_field.p_poly) == 1);
    // p_fun = succ (succ O) = 2
    check("function-typed variable", toInt(java_cons_fun_field.p_fun) == 2);
  }
}
