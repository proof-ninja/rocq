Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/lambda_object_target".

(* A Java lambda is typed by the target type of its position, and erasure
   makes every position that holds a type variable [Object], which is no
   target at all: javac rejects the bare lambda ("Object is not a
   functional interface"). Each definition below puts a lambda in one such
   position; the printer must supply the target by a cast. *)

Inductive nat := O | S : nat -> nat.
Inductive prod (A B : Type) := pair : A -> B -> prod A B.
Arguments pair {A B}.
Definition fst {A B} (p : prod A B) : A := match p with pair a _ => a end.
Definition idf {A : Type} (a : A) : A := a.

(* 1. Argument of a polymorphic constructor: the field is [Object], the
   instantiated type [nat -> nat] is the target. *)
Definition pair_fun : prod (nat -> nat) nat := pair (fun x => S x) O.
Definition use_pair_fun : nat := fst pair_fun O.

(* 2. Value of a [let]: the helper's type parameter is inferred from the
   value, which a lambda cannot drive. *)
Definition let_fun (n : nat) : nat := let f := fun x => S x in f (f n).

(* 3. Argument of a polymorphic function: the parameter is [Object]. *)
Definition apply_idf (n : nat) : nat := idf (fun x : nat => S x) n.

(* 4. Argument past the arrows of an over-applied polymorphic head: the
   receiver is bridged to [Function<Object, Object>], so the slot is
   [Object] too. *)
Definition over_idf (n : nat) : nat :=
  idf (fun (f : nat -> nat) (x : nat) => f x) (fun x => S x) n.

(* 1 inside polymorphic code: the instantiated field type is a type
   variable itself, so the target is [Function<Object, Object>] and the
   lambda's parameter is [Object]. *)
Definition pair_id {A : Type} (a : A) : prod (A -> A) A := pair (fun x => x) a.
Definition use_pair_id (n : nat) : nat := fst (pair_id n) (S n).

Extraction "java_lambda_object_target.java"
  use_pair_fun let_fun apply_idf over_idf use_pair_id.
