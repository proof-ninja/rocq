Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/singleton".

Inductive nat := O : nat | S : nat -> nat.
Inductive list (A : Type) := Nil : list A | Cons : A -> list A -> list A.
Arguments Nil {A}.
Arguments Cons {A}.

(* A one-constructor one-field inductive is classified [Singleton] by the
   extractor: its constructor and match are erased at the term level, so
   the Java printer must treat the type as a synonym of its field type
   rather than declare a wrapper class (issue #48). *)
Inductive wrapped := Wrap : nat -> wrapped.
Definition wrap (n : nat) : wrapped := Wrap n.
Definition unwrap (w : wrapped) : nat := match w with Wrap n => n end.

(* Parameterized singleton: the synonym substitutes the type argument. *)
Inductive box (A : Type) := Box : (A -> A) -> box A.
Arguments Box {A}.
Definition unbox {A : Type} (b : box A) : A -> A := match b with Box f => f end.
Definition succ (x : nat) : nat := S x.
(* A lambda and a global function at a singleton-typed position: before
   the fix, javac accepted [(box) (Object) succ] and the cast failed at
   run time with ClassCastException. *)
Definition apply_box_lam (n : nat) : nat := unbox (Box (fun x => S x)) n.
Definition apply_box_glob (n : nat) : nat := unbox (Box succ) n.

(* Singleton whose field is a bare type variable: the synonym body is the
   type variable itself, [Object] in polymorphic code and the instance at
   each monomorphic use. *)
Inductive id (A : Type) := Id : A -> id A.
Arguments Id {A}.
Definition unid {A : Type} (x : id A) : A := match x with Id a => a end.
Definition use_id (n : nat) : nat := S (unid (Id n)).
Definition use_id_fun (n : nat) : nat := unid (Id (fun x : nat => S x)) n.

(* Singleton of a singleton: expansion is recursive. *)
Inductive rewrapped := Rewrap : wrapped -> rewrapped.
Definition rewrap (n : nat) : rewrapped := Rewrap (Wrap n).
Definition unrewrap (r : rewrapped) : nat :=
  match r with Rewrap (Wrap n) => n end.

(* Singleton as a constructor field of an ordinary inductive, and as a
   type argument: the field type and the annotations are expanded. *)
Inductive holder := Hold : wrapped -> holder | Empty : holder.
Definition hold (n : nat) : holder := Hold (Wrap n).
Definition held (h : holder) : nat :=
  match h with
  | Hold w => unwrap w
  | Empty => O
  end.
Definition wrapped_list (n : nat) : list wrapped := Cons (Wrap n) Nil.
Definition first_unwrapped (l : list wrapped) : nat :=
  match l with
  | Nil => O
  | Cons w _ => unwrap w
  end.

(* A recursive definition ([Dfix]) over a singleton-typed argument. *)
Fixpoint add_wrapped (w : wrapped) (n : nat) : nat :=
  match n with
  | O => unwrap w
  | S m => S (add_wrapped w m)
  end.

Extraction "java_singleton.java"
  wrap unwrap apply_box_lam apply_box_glob unid use_id use_id_fun
  rewrap unrewrap hold held wrapped_list first_unwrapped add_wrapped.
