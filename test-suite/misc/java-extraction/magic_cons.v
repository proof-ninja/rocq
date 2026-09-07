Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/magic_cons".

Inductive nat : Set := O : nat | S : nat -> nat.
Inductive bool : Set := true : bool | false : bool.

(* A dependent match: the two branches don't have the same ML type ([nat] vs
   [bool]), so extraction inserts an MLmagic on at least one of them
   (needs_magic/mgu, mlutil.ml:116-142). The result is immediately built into
   a constructor ([S O]) whose own type annotation drives the cast
   regardless of the magic wrapping it -- this exercises that MLmagic stays
   transparent to a subterm that already carries its own type. *)
Definition dep (b : bool) : (if b then nat else bool) :=
  match b return (if b then nat else bool) with
  | true => S O
  | false => false
  end.

Definition use_dep : nat := dep true.

Extraction "java_magic_cons.java" use_dep.
