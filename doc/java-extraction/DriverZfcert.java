/*
 * Runtime driver for the Java-extracted ZFCert kernel (issue #28, step 5 of
 * zfcert-verification.md). Mirrors the extracted-kernel section of ZFCert's
 * src/self_test.ml: build named formulas directly, drive the certified
 * session (start -> rule steps -> solved -> finalize -> replay), and check
 * a couple of expected failures.
 *
 * Must live in the default package: the generated `class zfcert` and its
 * members are package-private.
 *
 * Usage: javac zfcert.java DriverZfcert.java && java DriverZfcert
 */
public class DriverZfcert {

  static int passed = 0;

  /* ---------- encoding helpers ---------- */

  static zfcert.bool b(boolean v) {
    return v ? new zfcert.True() : new zfcert.False();
  }

  // Coq's Ascii.ascii is LSB-first: Ascii b0 .. b7 with b0 the low bit.
  static zfcert.ascii ascii(char c) {
    return new zfcert.Ascii(
        b((c & 1) != 0), b((c & 2) != 0), b((c & 4) != 0), b((c & 8) != 0),
        b((c & 16) != 0), b((c & 32) != 0), b((c & 64) != 0), b((c & 128) != 0));
  }

  static zfcert.string str(String s) {
    zfcert.string r = new zfcert.EmptyString();
    for (int i = s.length() - 1; i >= 0; i--) {
      r = new zfcert.String0(ascii(s.charAt(i)), r);
    }
    return r;
  }

  static zfcert.list list(Object... items) {
    zfcert.list r = new zfcert.Nil();
    for (int i = items.length - 1; i >= 0; i--) {
      r = new zfcert.Cons(items[i], r);
    }
    return r;
  }

  static int listLength(zfcert.list l) {
    int n = 0;
    while (l instanceof zfcert.Cons) {
      n++;
      l = ((zfcert.Cons) l).Cons1;
    }
    return n;
  }

  /* ---------- formula construction ---------- */

  static zfcert.named_term name(String n) {
    return new zfcert.NName(str(n));
  }

  static zfcert.named_formula eq(zfcert.named_term a, zfcert.named_term b) {
    return new zfcert.NEqual(a, b);
  }

  static zfcert.named_formula mem(zfcert.named_term a, zfcert.named_term b) {
    return new zfcert.NMember(a, b);
  }

  static zfcert.named_formula all(String v, zfcert.named_formula f) {
    return new zfcert.NAll(str(v), f);
  }

  static zfcert.named_formula ex(String v, zfcert.named_formula f) {
    return new zfcert.NEx(str(v), f);
  }

  static zfcert.named_formula neg(zfcert.named_formula f) {
    return new zfcert.NNeg(f);
  }

  static zfcert.named_formula impl(zfcert.named_formula a, zfcert.named_formula b) {
    return new zfcert.NImpl(a, b);
  }

  /* ---------- kernel driving helpers ---------- */

  static final zfcert.list NO_AXIOMS = new zfcert.Nil();

  static zfcert.certificate_step step(zfcert.named_rule rule) {
    return zfcert.one_step.apply(NO_AXIOMS).apply(rule);
  }

  static Object ok(String what, zfcert.named_result r) {
    if (r instanceof zfcert.NOk) {
      return ((zfcert.NOk) r).NOk0;
    }
    zfcert.named_error e = ((zfcert.NError) r).NError0;
    throw new AssertionError(what + ": expected NOk but got NError("
        + e.getClass().getSimpleName() + ")");
  }

  static void expectError(String what, zfcert.named_result r) {
    if (r instanceof zfcert.NError) {
      zfcert.named_error e = ((zfcert.NError) r).NError0;
      System.out.println("  " + what + ": rejected with "
          + e.getClass().getSimpleName() + " as expected");
      passed++;
      return;
    }
    throw new AssertionError(what + ": expected NError but got NOk");
  }

  static void check(String what, boolean cond) {
    if (!cond) {
      throw new AssertionError(what + ": check failed");
    }
    System.out.println("  " + what + ": OK");
    passed++;
  }

  static zfcert.certified_state runRules(String what, zfcert.certified_state s,
      zfcert.named_rule... rules) {
    Object[] steps = new Object[rules.length];
    for (int i = 0; i < rules.length; i++) {
      steps[i] = step(rules[i]);
    }
    return (zfcert.certified_state)
        ok(what, zfcert.certified_run.apply(list(steps)).apply(s));
  }

  static boolean solved(zfcert.certified_state s) {
    return zfcert.certified_solved.apply(s) instanceof zfcert.True;
  }

  /* ---------- tests ---------- */

  // theorem refl : forall x, x = x  (rules: all_intro x; equal_refl),
  // then finalize and replay the certificate.
  static void testRefl() {
    System.out.println("test refl:");
    zfcert.named_formula source = all("x", eq(name("x"), name("x")));
    zfcert.certified_state s = (zfcert.certified_state)
        ok("start", zfcert.certified_start.apply(source));
    check("not solved at start", !solved(s));
    s = runRules("run [all_intro x; equal_refl]", s,
        new zfcert.NRAllIntro(str("x")), new zfcert.NREqualRefl());
    check("solved", solved(s));
    zfcert.list cert = (zfcert.list)
        ok("finalize", zfcert.certified_finalize.apply(s));
    check("certificate has 2 steps", listLength(cert) == 2);
    ok("replay", zfcert.replay_certificate.apply(source).apply(cert));
    check("replay accepted the certificate", true);
  }

  // Mirrors self_test.ml: start_with_constants ["empty"] (empty = empty),
  // equal_refl, solved, finalize.
  static void testConstants() {
    System.out.println("test constants:");
    zfcert.named_formula source = eq(name("empty"), name("empty"));
    zfcert.certified_state s = (zfcert.certified_state)
        ok("start_with_constants", zfcert.certified_start_with_constants
            .apply(list(str("empty"))).apply(source));
    s = (zfcert.certified_state) ok("equal_refl",
        zfcert.certified_step.apply(step(new zfcert.NREqualRefl())).apply(s));
    check("solved", solved(s));
    ok("finalize", zfcert.certified_finalize.apply(s));
    check("finalize accepted the constant environment", true);
  }

  // theorem rule_axiom : exists e, forall x, not (x in e)  (rule: axiom).
  // The goal must match the built-in empty-set axiom, so this is the one
  // test where driver-built strings meet kernel-internal strings.
  static void testFixedAxiom() {
    System.out.println("test fixed axiom:");
    zfcert.named_formula source =
        ex("e", all("x", neg(mem(name("x"), name("e")))));
    zfcert.certified_state s = (zfcert.certified_state)
        ok("start", zfcert.certified_start.apply(source));
    s = (zfcert.certified_state) ok("rule axiom",
        zfcert.certified_execute_rule.apply(new zfcert.NFixedAxiomRule())
            .apply(s));
    check("solved", solved(s));
    zfcert.list cert = (zfcert.list)
        ok("finalize", zfcert.certified_finalize.apply(s));
    ok("replay", zfcert.replay_certificate.apply(source).apply(cert));
    check("replay accepted the certificate", true);
  }

  // theorem : (p = p -> p = p) with constant p
  // (rules: impl_intro H; hypothesis H).
  static void testImplHypothesis() {
    System.out.println("test impl/hypothesis:");
    zfcert.named_formula pp = eq(name("p"), name("p"));
    zfcert.named_formula source = impl(pp, pp);
    zfcert.certified_state s = (zfcert.certified_state)
        ok("start_with_constants", zfcert.certified_start_with_constants
            .apply(list(str("p"))).apply(source));
    s = runRules("run [impl_intro H; hypothesis H]", s,
        new zfcert.NRImplIntro(str("H")), new zfcert.NRHypothesis(str("H")));
    check("solved", solved(s));
    zfcert.list cert = (zfcert.list)
        ok("finalize", zfcert.certified_finalize.apply(s));
    ok("replay", zfcert.replay_certificate.apply(source).apply(cert));
    check("replay accepted the certificate", true);
  }

  // The kernel must reject an equal_refl step on a non-reflexive goal
  // (self_test.ml: "The kernel accepted an invalid equality proof").
  static void testRejectBadRefl() {
    System.out.println("test bad refl is rejected:");
    zfcert.named_formula source =
        all("x", all("y", eq(name("x"), name("y"))));
    zfcert.certified_state s = (zfcert.certified_state)
        ok("start", zfcert.certified_start.apply(source));
    s = runRules("run [all_intro x; all_intro y]", s,
        new zfcert.NRAllIntro(str("x")), new zfcert.NRAllIntro(str("y")));
    expectError("equal_refl on x = y",
        zfcert.certified_step.apply(step(new zfcert.NREqualRefl())).apply(s));
  }

  // The kernel must reject a reference to an unknown hypothesis.
  static void testRejectUnknownHypothesis() {
    System.out.println("test unknown hypothesis is rejected:");
    zfcert.named_formula pp = eq(name("p"), name("p"));
    zfcert.certified_state s = (zfcert.certified_state)
        ok("start_with_constants", zfcert.certified_start_with_constants
            .apply(list(str("p"))).apply(impl(pp, pp)));
    s = runRules("run [impl_intro H]", s, new zfcert.NRImplIntro(str("H")));
    expectError("hypothesis 'missing'",
        zfcert.certified_step.apply(step(new zfcert.NRHypothesis(str("missing"))))
            .apply(s));
  }

  public static void main(String[] args) {
    testRefl();
    testConstants();
    testFixedAxiom();
    testImplHypothesis();
    testRejectBadRefl();
    testRejectUnknownHypothesis();
    System.out.println("All " + passed + " runtime checks passed.");
  }
}
