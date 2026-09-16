Require Corelib.extraction.Extraction.
Require Corelib.Numbers.BinNums.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/module_alias".

Inductive nat := O : nat | S : nat -> nat.

Module Other.
  Inductive point := P : nat -> nat -> point.
  Record rec : Type := MkRec { rx : nat; ry : nat }.
End Other.

(* [M.point] and [Other.point] are the same inductive in Rocq (the alias
   only changes the user-facing name). The Java printer must refer to a
   single declaration for both, otherwise a value built through one name
   cannot flow into a function typed through the other. *)
Module M := Other.

(* Cross-use in both directions. *)
Definition snd_of (p : Other.point) : nat := match p with Other.P _ y => y end.
Definition cross : nat := snd_of (M.P O (S O)).
Definition back (p : M.point) : Other.point := p.

(* Match through the alias name. *)
Definition fst_of (p : M.point) : nat := match p with M.P x _ => x end.

(* A record through the alias, incl. projections. *)
Definition rec_sum (r : M.rec) : nat :=
  match r with M.MkRec x y =>
    (fix add (m n : nat) : nat := match m with O => n | S m' => S (add m' n) end) x y
  end.
Definition mk_rec (x y : nat) : M.rec := M.MkRec x y.
Definition rec_x (r : M.rec) : nat := M.rx r.

(* An alias of a library module: the canonical block lives in another
   file and is mentioned only through the alias name, so it must survive
   dead-code removal (which decides by user name) and be declared under
   its canonical name. *)
Module B := Corelib.Numbers.BinNums.

Definition two : B.positive := B.xO B.xH.
Fixpoint digits (p : B.positive) : nat :=
  match p with
  | B.xH => S O
  | B.xO q => S (digits q)
  | B.xI q => S (digits q)
  end.
Definition two_digits : nat := digits two.

Extraction "java_module_alias.java"
  cross back fst_of rec_sum mk_rec rec_x two_digits digits.
