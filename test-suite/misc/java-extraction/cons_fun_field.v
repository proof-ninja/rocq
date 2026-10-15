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

Inductive box2 (A : Type) := Box2 : (A -> A) -> nat -> box2 A.
Arguments Box2 {A}.
Definition unbox2 {A} (b : box2 A) : A -> A :=
  match b with Box2 f _ => f end.
Definition succ (x : nat) := S x.

(* 1. A global function. *)
Definition p_glob : nat := unbox2 (Box2 succ O) O.

(* 2. A bare lambda: it keeps the instantiated type as its target and is
   bridged after that. *)
Definition p_lam : nat := unbox2 (Box2 (fun x => S x) O) O.

(* 3. A local variable and a partial application. *)
Definition mk_var (f : nat -> nat) : box2 nat := Box2 f O.
Definition mk_app (n : nat) : box2 nat := Box2 (add n) O.
Definition p_var : nat := unbox2 (mk_var succ) O.
Definition p_app : nat := unbox2 (mk_app (S O)) (S O).

(* 4. Inside polymorphic code the instantiated type erases to the declared
   one: no cast. *)
Definition mk_poly {A} (f : A -> A) : box2 A := Box2 f O.
Definition p_poly : nat := unbox2 (mk_poly succ) O.

(* 5. The type variable instantiated to a function type: the lambda's
   parameter is itself a function. *)
Definition p_fun : nat :=
  unbox2 (Box2 (fun (f : nat -> nat) => fun x => f (f x)) O) succ O.

(* 6. A lambda in tail position of a match branch or of a [let] body: the
   field itself is its target, so it takes the declared type ([Object]
   parameters) and the other branch is bridged on its own. *)
Inductive bool := true | false.
Definition mk_match (b : bool) : box2 nat :=
  Box2 (match b with true => succ | false => fun x => x end) O.
Definition p_match_true : nat := unbox2 (mk_match true) O.
Definition p_match_false : nat := unbox2 (mk_match false) (S O).
(* The branch lambda's [Object] parameter is cast where the body uses it
   at [nat]: the match-branch counterpart of [p_let]. A match whose
   branches all start with a lambda would not exercise this (see 8). *)
Definition mk_match_use (b : bool) : box2 nat :=
  Box2 (match b with true => succ | false => fun x => add x x end) O.
Definition p_match_use : nat := unbox2 (mk_match_use false) (S (S O)).
Definition p_let : nat :=
  unbox2 (Box2 (let f := add (S O) in fun x => f (f x)) O) O.

(* 7. A polymorphic application: its result is already [Object], so the
   cast needs no [(Object)] bridge. *)
Definition idf {A : Type} (a : A) : A := a.
Definition p_idf : nat := unbox2 (Box2 (idf succ) O) O.

(* 8. Every branch starts with a lambda: the extractor hoists the shared
   parameter out of the match, so the field receives a bare lambda whose
   body is a match with a lambda in one branch. The outer lambda keeps the
   instantiated type as its target and the branch lambda is typed through
   it. *)
Definition mk_hoist (b : bool) : box2 (nat -> nat) :=
  Box2 (match b with true => fun f => f | false => fun f x => f (f x) end) O.
Definition p_hoist : nat := unbox2 (mk_hoist false) succ O.

Extraction "java_cons_fun_field.java"
  p_glob p_lam p_var p_app p_poly p_fun p_match_true p_match_false p_match_use
  p_let p_idf p_hoist.
