Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/poly_head".

Inductive list (A : Type) := Nil : list A | Cons : A -> list A -> list A.
Arguments Nil {A}.
Arguments Cons {A}.

(* Returns its type variable: the erased Java result type is Object, so
   every use at a concrete type needs a printer-inserted cast. *)
Definition head {A} (d : A) (l : list A) : A :=
  match l with
  | Nil => d
  | Cons x _ => x
  end.

(* Cast on the result of a polymorphic application (static initializer). *)
Definition three : nat := head O (Cons (S (S (S O))) Nil).

(* The let-bound result of a polymorphic application used at a concrete
   type: the cast lands on the use of the bound variable. *)
Definition succ_head (l : list nat) : nat := let x := head O l in S x.

(* A match on a concretely instantiated polymorphic inductive: the cast
   lands on the constructor field access. *)
Definition first_or_zero (l : list nat) : nat :=
  match l with
  | Nil => O
  | Cons x _ => x
  end.

Extraction "java_poly_head.java" three succ_head first_or_zero.
