public class DriverSingleton {
  static java_singleton.nat intToNat(int n) {
    java_singleton.nat r = new java_singleton.O();
    for (int i = 0; i < n; i++) {
      r = new java_singleton.S(r);
    }
    return r;
  }

  static int natToInt(java_singleton.nat n) {
    int i = 0;
    while (n instanceof java_singleton.S) {
      i++;
      n = ((java_singleton.S) n).S0;
    }
    return i;
  }

  static void check(String name, int expected, java_singleton.nat actual) {
    int shown = natToInt(actual);
    if (expected != shown) {
      throw new AssertionError(name + ": expected " + expected + " but got " + shown);
    }
  }

  public static void main(String[] args) {
    // wrapped is a synonym of nat: wrap and unwrap are identities.
    java_singleton.nat w = java_singleton.wrap.apply(intToNat(3));
    check("wrap", 3, w);
    check("unwrap", 3, java_singleton.unwrap.apply(w));

    // unbox (Box (fun x => S x)) 4 = 5, unbox (Box succ) 4 = 5
    check("apply_box_lam", 5, java_singleton.apply_box_lam.apply(intToNat(4)));
    check("apply_box_glob", 5, java_singleton.apply_box_glob.apply(intToNat(4)));

    // unid (Id 2) = 2 as Object; use_id 2 = 3, use_id_fun 2 = 3
    check("unid", 2, (java_singleton.nat) java_singleton.unid.apply(intToNat(2)));
    check("use_id", 3, java_singleton.use_id.apply(intToNat(2)));
    check("use_id_fun", 3, java_singleton.use_id_fun.apply(intToNat(2)));

    // rewrapped is a synonym of wrapped, hence of nat.
    java_singleton.nat r = java_singleton.rewrap.apply(intToNat(2));
    check("rewrap", 2, r);
    check("unrewrap", 2, java_singleton.unrewrap.apply(r));

    // Hold (Wrap 6) carries a nat directly.
    java_singleton.holder h = java_singleton.hold.apply(intToNat(6));
    check("hold field", 6, ((java_singleton.Hold) h).Hold0);
    check("held", 6, java_singleton.held.apply(h));
    check("held empty", 0, java_singleton.held.apply(new java_singleton.Empty()));

    // wrapped_list 7 = [7]
    java_singleton.list l = java_singleton.wrapped_list.apply(intToNat(7));
    check("wrapped_list head", 7, (java_singleton.nat) ((java_singleton.Cons) l).Cons0);
    check("first_unwrapped", 7, java_singleton.first_unwrapped.apply(l));
    check("first_unwrapped nil", 0,
        java_singleton.first_unwrapped.apply(new java_singleton.Nil()));

    // add_wrapped (Wrap 3) 4 = 7
    check("add_wrapped", 7,
        java_singleton.add_wrapped.apply(intToNat(3)).apply(intToNat(4)));
  }
}
