Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/poly_receiver".

Definition poly_id {A : Type} (x : A) : A := x.

(* [poly_id f] instantiates the type variable to a function type: the
   erased receiver is Object, so the printer must cast it back to
   Function before the remaining application. *)
Definition apply_through_id (f : nat -> nat) (x : nat) : nat :=
  (poly_id f) (S x).

Definition result : nat := apply_through_id S O.

Extraction "java_poly_receiver.java" apply_through_id result.
