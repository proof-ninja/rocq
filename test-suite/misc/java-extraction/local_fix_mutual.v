Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/local_fix_mutual".

Inductive parity :=
| Even : parity
| Odd : parity.

Definition parity_of (n : nat) : parity :=
  (fix evenp (n : nat) : parity :=
    match n with
    | O => Even
    | S m => oddp m
    end
  with oddp (n : nat) : parity :=
    match n with
    | O => Odd
    | S m => evenp m
    end
  for evenp) n.

Definition parity_of_succ (n : nat) : parity :=
  (fix evenp (n : nat) : parity :=
    match n with
    | O => Even
    | S m => oddp m
    end
  with oddp (n : nat) : parity :=
    match n with
    | O => Odd
    | S m => evenp m
    end
  for oddp) (S (S n)).

Extraction "java_local_fix_mutual.java"
  parity_of parity_of_succ.
