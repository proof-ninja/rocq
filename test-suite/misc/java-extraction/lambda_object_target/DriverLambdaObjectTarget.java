public class DriverLambdaObjectTarget {
  static void check(String name, boolean ok) {
    if (!ok) {
      throw new AssertionError(name);
    }
  }

  static int toInt(java_lambda_object_target.nat n) {
    int i = 0;
    while (n instanceof java_lambda_object_target.S) {
      n = ((java_lambda_object_target.S) n).S0;
      i++;
    }
    return i;
  }

  public static void main(String[] args) {
    java_lambda_object_target.nat one =
        new java_lambda_object_target.S(new java_lambda_object_target.O());

    // use_pair_fun = fst (pair (fun x => S x) O) O = S O
    check("constructor field", toInt(java_lambda_object_target.use_pair_fun) == 1);
    // let_fun 1 = S (S 1)
    check("let value", toInt(java_lambda_object_target.let_fun.apply(one)) == 3);
    // apply_idf 1 = S 1
    check("polymorphic parameter", toInt(java_lambda_object_target.apply_idf.apply(one)) == 2);
    // over_idf 1 = (fun f x => f x) (fun x => S x) 1 = S 1
    check("past the arrows", toInt(java_lambda_object_target.over_idf.apply(one)) == 2);
    // use_pair_id 1 = (fun x => x) (S 1)
    check("field in polymorphic code", toInt(java_lambda_object_target.use_pair_id.apply(one)) == 2);
  }
}
