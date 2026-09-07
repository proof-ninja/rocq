public class DriverMonoBranchLam {
  static int natToInt(java_mono_branch_lam.nat n) {
    int i = 0;
    while (n instanceof java_mono_branch_lam.S) {
      i++;
      n = ((java_mono_branch_lam.S) n).S0;
    }
    return i;
  }

  public static void main(String[] args) {
    int shown = natToInt(java_mono_branch_lam.use_pick);
    if (shown != 1) {
      throw new AssertionError("use_pick: expected 1 but got " + shown);
    }
  }
}
