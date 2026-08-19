Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/type_alias".

Inductive nat := O : nat | S : nat -> nat.
Inductive list (A : Type) := Nil : list A | Cons : A -> list A -> list A.
Arguments Nil {A}.
Arguments Cons {A}.

(* Monomorphic alias to an inductive. *)
Definition natlist := list nat.
Definition singleton (n : nat) : natlist := Cons n Nil.

(* Alias to a function type: after expansion the arrows are visible again,
   so applying [f] needs no receiver cast. *)
Definition natop := nat -> nat.
Definition twice (f : natop) (n : nat) : nat := f (f n).

(* Parameterized alias: expansion substitutes the type argument. *)
Definition listlist (A : Type) := list (list A).
Definition wrap (n : nat) : listlist nat := Cons (Cons n Nil) Nil.

(* Alias of an alias: expansion is recursive. *)
Definition natlist2 := natlist.
Definition second (n : nat) : natlist2 := singleton (S n).

(* An inductive whose constructor field type is an alias. Two constructors
   on purpose: a one-constructor one-field inductive is classified Singleton
   by the extractor and hits a pre-existing java.ml issue unrelated to
   aliases (wrapper class printed but constructor/match elided). *)
Inductive box := Box : natop -> box | Nought : box.
Definition unbox (b : box) (n : nat) : nat :=
  match b with
  | Box f => f n
  | Nought => n
  end.

(* Alias as a type argument in constructor/match annotations. The
   constructor argument is a variable, not a lambda: a bare lambda in an
   [Object]-typed field position hits a pre-existing javac issue unrelated
   to aliases (missing functional-interface cast). *)
Definition singleton_op (f : natop) : list natop := Cons f Nil.
Definition apply_head (l : list natop) (n : nat) : nat :=
  match l with
  | Nil => n
  | Cons f _ => f n
  end.

(* An axiom type is an alias without a body; its values are Object. *)
Axiom abstract : Type.
Definition const_zero (x : abstract) : nat := O.

Extraction "java_type_alias.java"
  singleton twice wrap second unbox singleton_op apply_head const_zero.
