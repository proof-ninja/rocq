Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/poly_list".

(* A polymorphic inductive: its type parameter is erased to Object in the
   generated Java, and the classes stay non-generic. *)
Inductive list (A : Type) := Nil : list A | Cons : A -> list A -> list A.
Arguments Nil {A}.
Arguments Cons {A}.

Fixpoint app {A} (l1 l2 : list A) : list A :=
  match l1 with
  | Nil => l2
  | Cons x xs => Cons x (app xs l2)
  end.

Fixpoint reverse {A} (l : list A) : list A :=
  match l with
  | Nil => Nil
  | Cons x xs => app (reverse xs) (Cons x Nil)
  end.

(* A monomorphic instantiation, so the driver can exercise the polymorphic
   functions at type nat. *)
Definition reverse_nats (l : list nat) : list nat := reverse l.

Extraction "java_poly_list.java" reverse_nats.
