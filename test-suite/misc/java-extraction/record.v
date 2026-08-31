Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/record".

Inductive nat := O : nat | S : nat -> nat.

(* A Record extracts with [ind_kind = Record]: the declaration must use the
   same scheme as ordinary inductives (interface + constructor-named class
   with positional fields), because construction and match sites print
   [new MkPoint(...)] / [instanceof MkPoint] / positional [MkPoint0] fields. *)
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

(* A record with a Prop field in the middle: the field is erased by
   extraction, and the positional numbering of the remaining fields must
   agree between the declaration and the term sites. Two informative
   fields keep the record out of the [Singleton] classification. *)
Inductive is_zero : nat -> Prop := IsZero : is_zero O.

Record bounded : Type := MkBounded { blo : nat; bok : is_zero blo; bhi : nat }.

Definition mk_bounded : bounded := MkBounded O IsZero (S O).
Definition get_blo (b : bounded) : nat := blo b.
Definition get_bhi (b : bounded) : nat := bhi b.

(* A polymorphic record: type parameters are erased to Object, so field
   reads must go through the cast-insertion machinery. *)
Record pair (A B : Type) : Type := MkPair { pfst : A; psnd : B }.
Arguments MkPair {A B}.
Arguments pfst {A B}.
Arguments psnd {A B}.

Fixpoint add (m n : nat) : nat :=
  match m with O => n | S m' => S (add m' n) end.

Definition mk_nat_pair (x y : nat) : pair nat nat := MkPair x y.
Definition pair_sum (p : pair nat nat) : nat := add (pfst p) (psnd p).

(* A primitive-projections record: projections are expanded to matches at
   extraction time, so the same declaration scheme must apply. The
   attribute keeps the flag local to this record. *)
#[projections(primitive)]
Record ppoint : Type := MkPPoint { ppx : nat; ppy : nat }.

Definition mk_ppoint (x y : nat) : ppoint := MkPPoint x y.
Definition get_ppx (p : ppoint) : nat := ppx p.
Definition get_ppy (p : ppoint) : nat := ppy p.

Extraction "java_record.java" origin getx gety swap bump mk_inc apply_tagged
  mk_bounded get_blo get_bhi mk_nat_pair pair_sum mk_ppoint get_ppx get_ppy.
