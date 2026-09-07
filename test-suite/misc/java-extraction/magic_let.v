Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/magic_let".

Inductive nat : Set := O : nat | S : nat -> nat.
Inductive bool : Set := true : bool | false : bool.

Definition dep_fn2 (b : bool) : (if b then nat -> nat else bool) :=
  match b return (if b then nat -> nat else bool) with
  | true => S
  | false => true
  end.

(* Same magic-producing shape as magic_apply.v, but the function value is
   let-bound before being applied instead of applied directly. The whole
   application [f n] disagrees with its own let-bound name's erased type, so
   OCaml extraction puts the MLmagic on [f n] itself; mlutil.ml's [simpl]
   then rewrites that to MLmagic sitting on the callee ([f]), the head of an
   MLapp -- this is the position [type_of_expr]'s [MLmagic] case (java.ml)
   still unconditionally answers "unknown" for (recovering a type there was
   split out to #39, since no case here demonstrated actual harm from not
   doing so). *)
Definition indirect (n : nat) : nat :=
  let f := dep_fn2 true in f n.

Extraction "java_magic_let.java" indirect.
