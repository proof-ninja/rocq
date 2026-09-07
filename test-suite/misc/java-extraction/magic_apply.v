Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/magic_apply".

Inductive nat : Set := O : nat | S : nat -> nat.
Inductive bool : Set := true : bool | false : bool.

(* A dependent match returning a FUNCTION type in one branch: the erased
   Java type of [dep_fn b] is Object (the branches don't unify), so
   [dep_fn true] additionally passes through MLmagic (per the OCaml
   extraction of this file), and applying its result needs the same
   Object -> Function<Object, Object> bridge that poly_receiver.v exercises
   for plain Tvar erasure. *)
Definition dep_fn (b : bool) : (if b then nat -> nat else bool) :=
  match b return (if b then nat -> nat else bool) with
  | true => S
  | false => true
  end.

Definition apply_dep_fn : nat := dep_fn true O.

Extraction "java_magic_apply.java" apply_dep_fn.
