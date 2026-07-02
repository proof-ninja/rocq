Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/basic_arithmetic".

Inductive nat : Set :=
| O : nat
| S : nat -> nat.

Fixpoint add (n m : nat) : nat :=
  match n with
  | O => m
  | S n' => S (add n' m)
  end.

Definition double (n : nat) : nat := add n n.

Fixpoint mul (n m : nat) : nat :=
  match n with
  | O => O
  | S n' => add m (mul n' m)
  end.

Definition two : nat := S (S O).
Definition three : nat := S two.

Extraction "java_arithmetic_demo.java"
  add double mul two three.

Extraction "java_constants_demo.java"
  two three.
