Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/cons_fun_field".

(* A constructor field whose declared type is a function type over the
   inductive's type variables ([A -> A]) has the static Java type
   [Function<Object, Object>]. A value built for it is printed at the
   instantiated type ([Function<nat, nat>]), and Java generics are
   invariant, so the argument must be bridged to the declared type the
   same way a pattern match bridges the field access back. *)

Inductive nat := O | S : nat -> nat.
Fixpoint add (m n : nat) : nat :=
  match m with O => n | S m' => S (add m' n) end.

Inductive fnbox (A : Type) := MkFnbox : (A -> A) -> nat -> fnbox A.
Arguments MkFnbox {A}.
Definition unfnbox {A} (b : fnbox A) : A -> A :=
  match b with MkFnbox f _ => f end.
Definition succ (x : nat) := S x.

(* 1. A global function. *)
Definition p_glob : nat := unfnbox (MkFnbox succ O) O.

(* 2. A bare lambda: it keeps the instantiated type as its target and is
   bridged after that. *)
Definition p_lam : nat := unfnbox (MkFnbox (fun x => S x) O) O.

(* 3. A local variable and a partial application. *)
Definition mk_var (f : nat -> nat) : fnbox nat := MkFnbox f O.
Definition mk_app (n : nat) : fnbox nat := MkFnbox (add n) O.
Definition p_var : nat := unfnbox (mk_var succ) O.
Definition p_app : nat := unfnbox (mk_app (S O)) (S O).

(* 4. Inside polymorphic code the instantiated type erases to the declared
   one: no cast. *)
Definition mk_poly {A} (f : A -> A) : fnbox A := MkFnbox f O.
Definition p_poly : nat := unfnbox (mk_poly succ) O.

(* 5. The type variable instantiated to a function type: the lambda's
   parameter is itself a function. *)
Definition p_fun : nat :=
  unfnbox (MkFnbox (fun (f : nat -> nat) => fun x => f (f x)) O) succ O.

(* 6. A lambda in tail position of a match branch or of a [let] body: the
   field itself is its target, so it takes the declared type ([Object]
   parameters) and the other branch is bridged on its own. *)
Inductive bool := true | false.
Definition mk_match (b : bool) : fnbox nat :=
  MkFnbox (match b with true => succ | false => fun x => x end) O.
Definition p_match_true : nat := unfnbox (mk_match true) O.
Definition p_match_false : nat := unfnbox (mk_match false) (S O).
Definition p_let : nat :=
  unfnbox (MkFnbox (let f := add (S O) in fun x => f (f x)) O) O.

(* 7. A polymorphic application: its result is already [Object], so the
   cast needs no [(Object)] bridge. *)
Definition idf {A : Type} (a : A) : A := a.
Definition p_idf : nat := unfnbox (MkFnbox (idf succ) O) O.

Extraction "java_cons_fun_field.java"
  p_glob p_lam p_var p_app p_poly p_fun p_match_true p_match_false p_let p_idf.
