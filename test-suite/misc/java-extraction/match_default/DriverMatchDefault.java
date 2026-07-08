public class DriverMatchDefault {
  static void assertColor(String label, Main.color actual, Class<?> expected) {
    if (!expected.equals(actual.getClass())) {
      throw new AssertionError(label + ": expected " + expected.getName() + " but got " + actual.getClass().getName());
    }
  }

  public static void main(String[] args) {
    // default_to_red: Red => Green | _ => Red (Pwild catch-all)
    assertColor("default_to_red(Red)", Main.default_to_red.apply(new Main.Red()), Main.Green.class);
    assertColor("default_to_red(Green)", Main.default_to_red.apply(new Main.Green()), Main.Red.class);
    assertColor("default_to_red(Blue)", Main.default_to_red.apply(new Main.Blue()), Main.Red.class);

    // normalize: match default_to_red c with Red => Green | other => other
    // (Prel catch-all binding the compound scrutinee to a variable)
    assertColor("normalize(Red)", Main.normalize.apply(new Main.Red()), Main.Green.class);
    assertColor("normalize(Green)", Main.normalize.apply(new Main.Green()), Main.Green.class);
    assertColor("normalize(Blue)", Main.normalize.apply(new Main.Blue()), Main.Green.class);

    // A catch-all branch matches values beyond the extracted constructors, so
    // even a foreign implementer of the interface takes the default branch
    // instead of raising a match failure.
    Main.color alien = new Main.color() {};
    assertColor("default_to_red(alien)", Main.default_to_red.apply(alien), Main.Red.class);
    assertColor("normalize(alien)", Main.normalize.apply(alien), Main.Green.class);
  }
}
