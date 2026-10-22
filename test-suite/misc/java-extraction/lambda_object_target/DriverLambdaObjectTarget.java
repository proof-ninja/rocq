public class DriverLambdaObjectTarget {
  static void check(String name, boolean ok) {
    if (!ok) {
      throw new AssertionError(name);
    }
  }

  static int toInt(java_lambda_object_target.nat n) {
    int i = 0;
    while (n instanceof java_lambda_object_target.nat.S) {
      n = ((java_lambda_object_target.nat.S) n).S0;
      i++;
    }
    return i;
  }

  public static void main(String[] args) {
    java_lambda_object_target.nat one =
        new java_lambda_object_target.nat.S(new java_lambda_object_target.nat.O());

    // use_pair_fun = fst (pair (fun x => S x) O) O = S O
    check("constructor field", toInt(java_lambda_object_target.use_pair_fun) == 1);
    // let_fun 1 = S (S 1)
    check("let value", toInt(java_lambda_object_target.let_fun.apply(one)) == 3);
    // let_match true 1 = succ (succ 1) = 3; let_match false 1 = 1
    check("let value: match with a lambda branch (true)",
        toInt(java_lambda_object_target.let_match.apply(
            new java_lambda_object_target.bool.True()).apply(one)) == 3);
    check("let value: match with a lambda branch (false)",
        toInt(java_lambda_object_target.let_match.apply(
            new java_lambda_object_target.bool.False()).apply(one)) == 1);
    // let_match_arity TA 1 = add (add 1 1) 1 = 3
    check("let value: global branch among lambdas",
        toInt(java_lambda_object_target.let_match_arity.apply(
            new java_lambda_object_target.tri.TA()).apply(one)) == 3);
    // let_match_arity TB 1 = add (S (add (S 1) 1)) 1 = 5
    check("let value: shorter lambda branch",
        toInt(java_lambda_object_target.let_match_arity.apply(
            new java_lambda_object_target.tri.TB()).apply(one)) == 5);
    // let_match_arity TC 1 = add 1 (add 1 1) = 3
    check("let value: longer lambda branch",
        toInt(java_lambda_object_target.let_match_arity.apply(
            new java_lambda_object_target.tri.TC()).apply(one)) == 3);
    // let_fix_match true 1 = succ (succ 1) = 3
    check("let value: fix-headed inner let (true)",
        toInt(java_lambda_object_target.let_fix_match.apply(
            new java_lambda_object_target.bool.True()).apply(one)) == 3);
    // let_fix_match false 1 = succ (1 + S 1) = 4 (for any argument)
    check("let value: fix-headed inner let (false)",
        toInt(java_lambda_object_target.let_fix_match.apply(
            new java_lambda_object_target.bool.False()).apply(one)) == 4);
    // unknown_leaf true true 1 = succ (succ (succ 1)) = 4
    check("let value: unknown-typed branch (true, true)",
        toInt(java_lambda_object_target.unknown_leaf.apply(
            new java_lambda_object_target.bool.True()).apply(
            new java_lambda_object_target.bool.True()).apply(one)) == 4);
    // unknown_leaf false true 1 = pred (pred (pred 1)) = 0
    check("let value: unknown-typed branch (false, true)",
        toInt(java_lambda_object_target.unknown_leaf.apply(
            new java_lambda_object_target.bool.False()).apply(
            new java_lambda_object_target.bool.True()).apply(one)) == 0);
    // unknown_leaf true false 1 = succ 1 = 2
    check("let value: unknown-typed branch (true, false)",
        toInt(java_lambda_object_target.unknown_leaf.apply(
            new java_lambda_object_target.bool.True()).apply(
            new java_lambda_object_target.bool.False()).apply(one)) == 2);
    // unknown_app true true 1 = add 1 (add 1 (add 1 1)) = 4
    check("let value: unknown-typed application (true, true)",
        toInt(java_lambda_object_target.unknown_app.apply(
            new java_lambda_object_target.bool.True()).apply(
            new java_lambda_object_target.bool.True()).apply(one)) == 4);
    // unknown_app false true 1: h 1 1 = 3, then x + 2 twice = 7
    check("let value: unknown-typed application (false, true)",
        toInt(java_lambda_object_target.unknown_app.apply(
            new java_lambda_object_target.bool.False()).apply(
            new java_lambda_object_target.bool.True()).apply(one)) == 7);
    // unknown_app true false 1 = add 1 1 = 2
    check("let value: unknown-typed application (true, false)",
        toInt(java_lambda_object_target.unknown_app.apply(
            new java_lambda_object_target.bool.True()).apply(
            new java_lambda_object_target.bool.False()).apply(one)) == 2);
    // let_match_scrut true 1 = 1 (neg true = false)
    check("let value: compound scrutinee (true)",
        toInt(java_lambda_object_target.let_match_scrut.apply(
            new java_lambda_object_target.bool.True()).apply(one)) == 1);
    // let_match_scrut false 1 = succ (succ 1) = 3
    check("let value: compound scrutinee (false)",
        toInt(java_lambda_object_target.let_match_scrut.apply(
            new java_lambda_object_target.bool.False()).apply(one)) == 3);
    // apply_idf 1 = S 1
    check("polymorphic parameter", toInt(java_lambda_object_target.apply_idf.apply(one)) == 2);
    // over_idf 1 = (fun f x => f x) (fun x => S x) 1 = S 1
    check("past the arrows", toInt(java_lambda_object_target.over_idf.apply(one)) == 2);
    // use_pair_id 1 = (fun x => x) (S 1)
    check("field in polymorphic code", toInt(java_lambda_object_target.use_pair_id.apply(one)) == 2);
  }
}
