public class DriverLangShadow {
  static void check(String name, boolean ok) {
    if (!ok) {
      throw new AssertionError(name);
    }
  }

  public static void main(String[] args) {
    // dot_prefix EmptyString = String Dot EmptyString
    java_lang_shadow.string s =
        java_lang_shadow.dot_prefix.apply(new java_lang_shadow.EmptyString());
    check("dot_prefix wraps", s instanceof java_lang_shadow.String0);
    java_lang_shadow.String0 c = (java_lang_shadow.String0) s;
    check("dot_prefix head", c.String00 instanceof java_lang_shadow.Dot);
    check("dot_prefix tail", c.String01 instanceof java_lang_shadow.EmptyString);

    // rotate cycles Function -> RuntimeException -> SuppressWarnings -> Object
    check("rotate Function",
        java_lang_shadow.rotate.apply(new java_lang_shadow.Function0())
            instanceof java_lang_shadow.RuntimeException0);
    check("rotate RuntimeException",
        java_lang_shadow.rotate.apply(new java_lang_shadow.RuntimeException0())
            instanceof java_lang_shadow.SuppressWarnings0);
    check("rotate SuppressWarnings",
        java_lang_shadow.rotate.apply(new java_lang_shadow.SuppressWarnings0())
            instanceof java_lang_shadow.Object0);
    check("rotate Object",
        java_lang_shadow.rotate.apply(new java_lang_shadow.Object0())
            instanceof java_lang_shadow.Function0);
  }
}
