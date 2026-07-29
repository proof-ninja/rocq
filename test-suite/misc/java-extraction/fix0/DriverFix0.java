import java.util.function.Function;

public class DriverFix0 {
  static Main.nat intToNat(int n) {
    Main.nat r = new Main.O();
    for (int i = 0; i < n; i++) {
      r = new Main.S(r);
    }
    return r;
  }

  static int natToInt(Main.nat n) {
    int i = 0;
    while (n instanceof Main.S) {
      i++;
      n = ((Main.S) n).S0;
    }
    return i;
  }

  static Main.natlist build(int... xs) {
    Main.natlist l = new Main.Nil();
    for (int i = xs.length - 1; i >= 0; i--) {
      l = new Main.Cons(intToNat(xs[i]), l);
    }
    return l;
  }

  static String show(Main.natlist l) {
    StringBuilder sb = new StringBuilder("[");
    boolean first = true;
    while (l instanceof Main.Cons) {
      Main.Cons c = (Main.Cons) l;
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

  static void assertList(String expected, Main.natlist actual) {
    String actualShown = show(actual);
    if (!expected.equals(actualShown)) {
      throw new AssertionError("expected " + expected + " but got " + actualShown);
    }
  }

  public static void main(String[] args) {
    // The value Rocq hands back here was built by fix0.
    Function<Main.natlist, Function<Main.natlist, Main.natlist>> rev =
        Main.rev_selector.apply(new Main.Reverse());

    // 1. fix0 -> fix1 delegation actually performs the recursion.
    assertList("[3; 2; 1]", rev.apply(build(1, 2, 3)).apply(new Main.Nil()));
    // 2. base case: fix1 entered once, no recursive step.
    assertList("[]", rev.apply(build()).apply(new Main.Nil()));
    // 3. the fix0 value is reusable and carries no per-call state.
    assertList("[9; 8; 7; 6; 5; 4; 3; 2; 1; 0]",
        rev.apply(build(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)).apply(new Main.Nil()));
    // 4. R is instantiated to a function type: the intermediate value
    //    returned by fix1 is itself a correct, reusable closure.
    Function<Main.natlist, Main.natlist> onto = rev.apply(build(1, 2, 3));
    assertList("[3; 2; 1]", onto.apply(new Main.Nil()));
    assertList("[3; 2; 1; 9]", onto.apply(build(9)));
    // 5. the sibling branch of the match holding the fix0 call still works.
    assertList("[1; 2; 3; 7]",
        Main.rev_selector.apply(new Main.Keep()).apply(build(1, 2, 3)).apply(build(7)));
    // 6. fix0 in argument position: iterate applies the same value repeatedly.
    assertList("[3; 2; 1]", Main.rev_iterated.apply(intToNat(1)).apply(build(1, 2, 3)));
    assertList("[1; 2; 3]", Main.rev_iterated.apply(intToNat(2)).apply(build(1, 2, 3)));
    assertList("[1; 2; 3]", Main.rev_iterated.apply(intToNat(0)).apply(build(1, 2, 3)));
  }
}
