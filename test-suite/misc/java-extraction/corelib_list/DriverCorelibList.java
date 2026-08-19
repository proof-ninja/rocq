public class DriverCorelibList {
  static int natToInt(java_corelib_list.nat n) {
    int i = 0;
    while (n instanceof java_corelib_list.S) {
      i++;
      n = ((java_corelib_list.S) n).S0;
    }
    return i;
  }

  // Elements come back erased (Cons0 is declared Object), so reading them
  // at type nat is the caller's (checked) cast.
  static String show(java_corelib_list.list l) {
    StringBuilder sb = new StringBuilder("[");
    boolean first = true;
    while (l instanceof java_corelib_list.Cons) {
      java_corelib_list.Cons c = (java_corelib_list.Cons) l;
      if (!first) {
        sb.append("; ");
      }
      sb.append(natToInt((java_corelib_list.nat) c.Cons0));
      first = false;
      l = c.Cons1;
    }
    sb.append("]");
    return sb.toString();
  }

  static void check(String name, boolean ok) {
    if (!ok) {
      throw new AssertionError(name);
    }
  }

  public static void main(String[] args) {
    check("doubled", "[1; 2; 1; 2]".equals(show(java_corelib_list.doubled)));

    check("first is Some", java_corelib_list.first instanceof java_corelib_list.Some);
    check("first value", natToInt((java_corelib_list.nat) ((java_corelib_list.Some) java_corelib_list.first).Some0) == 1);

    check("swapped is Pair", java_corelib_list.swapped instanceof java_corelib_list.Pair);
    java_corelib_list.Pair p = (java_corelib_list.Pair) java_corelib_list.swapped;
    check("swapped fst", natToInt((java_corelib_list.nat) p.Pair0) == 1);
    check("swapped snd", p.Pair1 instanceof java_corelib_list.True);
  }
}
