public class DriverMatchDefault {
  static void assertColor(String label, java_match_default.color actual, Class<?> expected) {
    if (!expected.equals(actual.getClass())) {
      throw new AssertionError(label + ": expected " + expected.getName() + " but got " + actual.getClass().getName());
    }
  }

  public static void main(String[] args) {
    // default_to_red: Red => Green | _ => Red (Pwild catch-all)
    assertColor("default_to_red(Red)", java_match_default.default_to_red.apply(new java_match_default.Red()), java_match_default.Green.class);
    assertColor("default_to_red(Green)", java_match_default.default_to_red.apply(new java_match_default.Green()), java_match_default.Red.class);
    assertColor("default_to_red(Blue)", java_match_default.default_to_red.apply(new java_match_default.Blue()), java_match_default.Red.class);

    // normalize: match default_to_red c with Red => Green | other => other
    // (Prel catch-all binding the compound scrutinee to a variable)
    assertColor("normalize(Red)", java_match_default.normalize.apply(new java_match_default.Red()), java_match_default.Green.class);
    assertColor("normalize(Green)", java_match_default.normalize.apply(new java_match_default.Green()), java_match_default.Green.class);
    assertColor("normalize(Blue)", java_match_default.normalize.apply(new java_match_default.Blue()), java_match_default.Green.class);

    // A catch-all branch matches values beyond the extracted constructors, so
    // even a foreign implementer of the interface takes the default branch
    // instead of raising a match failure.
    java_match_default.color alien = new java_match_default.color() {};
    assertColor("default_to_red(alien)", java_match_default.default_to_red.apply(alien), java_match_default.Red.class);
    assertColor("normalize(alien)", java_match_default.normalize.apply(alien), java_match_default.Green.class);
  }
}
