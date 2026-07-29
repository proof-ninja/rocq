public class DriverCorelibList {
  static int natToInt(Main.nat n) {
    int i = 0;
    while (n instanceof Main.S) {
      i++;
      n = ((Main.S) n).S0;
    }
    return i;
  }

  // Elements come back erased (Cons0 is declared Object), so reading them
  // at type nat is the caller's (checked) cast.
  static String show(Main.list l) {
    StringBuilder sb = new StringBuilder("[");
    boolean first = true;
    while (l instanceof Main.Cons) {
      Main.Cons c = (Main.Cons) l;
      if (!first) {
        sb.append("; ");
      }
      sb.append(natToInt((Main.nat) c.Cons0));
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
    check("doubled", "[1; 2; 1; 2]".equals(show(Main.doubled)));

    check("first is Some", Main.first instanceof Main.Some);
    check("first value", natToInt((Main.nat) ((Main.Some) Main.first).Some0) == 1);

    check("swapped is Pair", Main.swapped instanceof Main.Pair);
    Main.Pair p = (Main.Pair) Main.swapped;
    check("swapped fst", natToInt((Main.nat) p.Pair0) == 1);
    check("swapped snd", p.Pair1 instanceof Main.True);
  }
}
