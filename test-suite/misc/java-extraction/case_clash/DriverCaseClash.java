public class DriverCaseClash {
  static void check(String label, boolean ok) {
    if (!ok) {
      throw new AssertionError(label);
    }
  }

  public static void main(String[] args) {
    // A type and its own constructor coexist: ascii and ascii.Ascii
    java_case_clash.ascii a = new java_case_clash.ascii.Ascii(
        new java_case_clash.bool.True(), new java_case_clash.bool.False());
    check("ascii_fst", java_case_clash.ascii_fst.apply(a) instanceof java_case_clash.bool.True);

    // Same constructor names up to case in distinct types: p.Leaf and q.LEAF
    check("p_to_q(Leaf)",
          java_case_clash.p_to_q.apply(new java_case_clash.p.Leaf()) instanceof java_case_clash.q.LEAF);
    check("p_to_q(Node)",
          java_case_clash.p_to_q.apply(new java_case_clash.p.Node()) instanceof java_case_clash.q.NODE);

    // Types equal up to case: foobar is renamed to foobar0
    java_case_clash.foobar0 w = java_case_clash.wrap.apply(new java_case_clash.fooBar.FB2());
    check("wrap", w instanceof java_case_clash.foobar0.Fb);
    check("unwrap(wrap(FB2))", java_case_clash.unwrap.apply(w) instanceof java_case_clash.fooBar.FB2);
    check("unwrap(NoFb)",
          java_case_clash.unwrap.apply(new java_case_clash.foobar0.NoFb()) instanceof java_case_clash.fooBar.FB1);

    // Constructors of a same type equal up to case: AB is renamed to AB0
    check("flip(Ab)", java_case_clash.flip.apply(new java_case_clash.ab.Ab()) instanceof java_case_clash.ab.AB0);
    check("flip(AB)", java_case_clash.flip.apply(new java_case_clash.ab.AB0()) instanceof java_case_clash.ab.Ab);

    // A type named like the top-level class is renamed to java_case_clash0
    java_case_clash.java_case_clash0 c = java_case_clash.clash_flip.apply(
        new java_case_clash.java_case_clash0.Clash(new java_case_clash.ab.Ab()));
    check("clash_flip(Clash Ab)",
          c instanceof java_case_clash.java_case_clash0.Clash
          && ((java_case_clash.java_case_clash0.Clash) c).Clash0 instanceof java_case_clash.ab.AB0);
    check("clash_flip(NoClash)",
          java_case_clash.clash_flip.apply(new java_case_clash.java_case_clash0.NoClash())
            instanceof java_case_clash.java_case_clash0.NoClash);
  }
}
