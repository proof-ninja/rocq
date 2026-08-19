Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/corelib_list".

(* Corelib's own polymorphic types (list, option, prod) extract as erased,
   non-generic classes; no hand-rolled monomorphic copies needed. *)

Definition sample : list nat := cons (S O) (cons (S (S O)) nil).

Definition doubled : list nat := app sample sample.

Definition first : option nat :=
  match sample with
  | nil => None
  | cons x _ => Some x
  end.

Definition swap {A B} (p : A * B) : B * A :=
  match p with
  | (a, b) => (b, a)
  end.

Definition swapped : nat * bool := swap (true, S O).

Extraction "java_corelib_list.java" doubled first swapped.
