Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/record".

Inductive nat := O : nat | S : nat -> nat.

(* A Record extracts with [ind_kind = Record]: the declaration must use the
   same scheme as ordinary inductives (interface + constructor-named class
   with positional fields), because construction and match sites print
   [new MkPoint(...)] / [instanceof MkPoint] / [((MkPoint)p).MkPoint0]. *)
Record point : Type := MkPoint { px : nat; py : nat }.

Definition origin : point := MkPoint O O.
Definition getx (p : point) : nat := px p.
Definition gety (p : point) : nat := py p.
Definition swap (p : point) : point := MkPoint (py p) (px p).
Definition bump (p : point) : point := MkPoint (S (px p)) (py p).

(* A record with a function-typed field. *)
Record tagged : Type := MkTagged { tag : nat; op : nat -> nat }.

Definition mk_inc : tagged := MkTagged O S.
Definition apply_tagged (t : tagged) (n : nat) : nat := op t n.

Extraction "java_record.java" origin getx gety swap bump mk_inc apply_tagged.
