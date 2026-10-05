Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/let_runout".

(* A polymorphic head applied past its arrows returns a type variable
   instantiated to a function; the printer bridges the remaining [.apply]
   calls through [Function<Object, Object>], so the value's static Java
   type is [Object]. A [let] binding such a value must give the bound
   variable that type, so that a use at a concrete type gets its cast:
   the [let] helper infers its type parameter from the value, which
   leaves the variable [Object] in the body. *)

Inductive nat := O | S : nat -> nat.
Definition idf {A : Type} (a : A) : A := a.
Fixpoint add (m n : nat) : nat :=
  match m with O => n | S m' => S (add m' n) end.

(* 1. The bound variable at a monomorphic parameter position. *)
Definition let_runout (f : nat -> nat) (n : nat) : nat :=
  let m := idf f n in add m m.

(* 2. The bound variable in a constructor field. *)
Definition let_runout_cons (f : nat -> nat) (n : nat) : nat :=
  let m := idf f n in S m.

(* 3. The bound variable at an [Object] position needs no cast. *)
Definition let_runout_poly (f : nat -> nat) (n : nat) : nat :=
  let m := idf f n in idf m.

(* 4. The bound value is itself a function: its applications are bridged
   the same way as the over-application that produced it. *)
Definition let_runout_fun (f : nat -> nat) (n : nat) : nat :=
  let g := idf idf f in S (g n).

(* Reference: the same value placed directly as an argument. *)
Definition arg_runout (f : nat -> nat) (n : nat) : nat := S (idf f n).

Extraction "java_let_runout.java"
  let_runout let_runout_cons let_runout_poly let_runout_fun arg_runout.
