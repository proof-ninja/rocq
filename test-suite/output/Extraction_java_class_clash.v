From Corelib Require Extraction.

Extraction Language Java.

(* Types equal up to case: the one referenced second is renamed. The
   warning names the Rocq type behind the kept class, as it differs from the
   class name. *)
Module M.
Inductive fooBar := FB1 | FB2.
End M.
Inductive foobar := Fb : M.fooBar -> foobar | NoFb.

Definition wrap (x : M.fooBar) : foobar := Fb x.

(* Constructors of a same type equal up to case. *)
Inductive ab := Ab | AB.

Definition flip (x : ab) : ab := match x with Ab => AB | AB => Ab end.

Recursive Extraction wrap flip.
