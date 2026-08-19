Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/type_alias_noexpand".

(* The Java backend's alias expansion must not depend on the global
   [TypeExpand] flag: with it unset, upstream extraction keeps aliases in
   expression-embedded type annotations (MLcons/MLcase), and java.ml must
   expand them itself. Same shapes as type_alias's singleton_op/apply_head. *)
Unset Extraction TypeExpand.

Inductive nat := O : nat | S : nat -> nat.
Inductive list (A : Type) := Nil : list A | Cons : A -> list A -> list A.
Arguments Nil {A}.
Arguments Cons {A}.

Definition natop := nat -> nat.
Definition singleton_op (f : natop) : list natop := Cons f Nil.
Definition apply_head (l : list natop) (n : nat) : nat :=
  match l with
  | Nil => n
  | Cons f _ => f n
  end.

Extraction "java_type_alias_noexpand.java" singleton_op apply_head.
