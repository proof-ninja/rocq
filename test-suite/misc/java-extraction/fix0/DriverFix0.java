import java.util.function.Function;

public class DriverFix0 {
  static java_fix0.nat intToNat(int n) {
    java_fix0.nat r = new java_fix0.O();
    for (int i = 0; i < n; i++) {
      r = new java_fix0.S(r);
    }
    return r;
  }

  static int natToInt(java_fix0.nat n) {
    int i = 0;
    while (n instanceof java_fix0.S) {
      i++;
      n = ((java_fix0.S) n).S0;
    }
    return i;
  }

  static java_fix0.natlist build(int... xs) {
    java_fix0.natlist l = new java_fix0.Nil();
    for (int i = xs.length - 1; i >= 0; i--) {
      l = new java_fix0.Cons(intToNat(xs[i]), l);
    }
    return l;
  }

  static String show(java_fix0.natlist l) {
    StringBuilder sb = new StringBuilder("[");
    boolean first = true;
    while (l instanceof java_fix0.Cons) {
      java_fix0.Cons c = (java_fix0.Cons) l;
      if (!first) {
        sb.append("; ");
      }
      sb.append(natToInt(c.Cons0));
      first = false;
      l = c.Cons1;
    }
    sb.append("]");
    return sb.toString();
  }

  static void assertList(String expected, java_fix0.natlist actual) {
    String actualShown = show(actual);
    if (!expected.equals(actualShown)) {
      throw new AssertionError("expected " + expected + " but got " + actualShown);
    }
  }

  public static void main(String[] args) {
    // The value Rocq hands back here was built by fix0.
    Function<java_fix0.natlist, Function<java_fix0.natlist, java_fix0.natlist>> rev =
        java_fix0.rev_selector.apply(new java_fix0.Reverse());

    // 1. fix0 -> fix1 delegation actually performs the recursion.
    assertList("[3; 2; 1]", rev.apply(build(1, 2, 3)).apply(new java_fix0.Nil()));
    // 2. base case: fix1 entered once, no recursive step.
    assertList("[]", rev.apply(build()).apply(new java_fix0.Nil()));
    // 3. the fix0 value is reusable and carries no per-call state.
    assertList("[9; 8; 7; 6; 5; 4; 3; 2; 1; 0]",
        rev.apply(build(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)).apply(new java_fix0.Nil()));
    // 4. R is instantiated to a function type: the intermediate value
    //    returned by fix1 is itself a correct, reusable closure.
    Function<java_fix0.natlist, java_fix0.natlist> onto = rev.apply(build(1, 2, 3));
    assertList("[3; 2; 1]", onto.apply(new java_fix0.Nil()));
    assertList("[3; 2; 1; 9]", onto.apply(build(9)));
    // 5. the sibling branch of the match holding the fix0 call still works.
    assertList("[1; 2; 3; 7]",
        java_fix0.rev_selector.apply(new java_fix0.Keep()).apply(build(1, 2, 3)).apply(build(7)));
    // 6. fix0 in argument position: iterate applies the same value repeatedly.
    assertList("[3; 2; 1]", java_fix0.rev_iterated.apply(intToNat(1)).apply(build(1, 2, 3)));
    assertList("[1; 2; 3]", java_fix0.rev_iterated.apply(intToNat(2)).apply(build(1, 2, 3)));
    assertList("[1; 2; 3]", java_fix0.rev_iterated.apply(intToNat(0)).apply(build(1, 2, 3)));
  }
}
