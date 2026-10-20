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

(* 2b. The value is a match with a lambda in one branch (issue #58). The
   branch lambda has no target either, and the two operands of the
   conditional must agree: the lambda casts itself and the global [succ]
   is bridged to the same [Function<Object, Object>]. [f] is used twice
   so that the [let] survives the optimizer (a single use is inlined). *)
Definition succ (x : nat) : nat := S x.
Inductive bool := true | false.
Definition let_match (b : bool) (n : nat) : nat :=
  let f := match b with true => succ | false => fun x => x end in f (f n).

(* 2c. The branch lambdas differ in arity: the shared target is built from
   the shorter one, and the longer lambda is bridged to it. One branch is
   a global so that the lambdas are not hoisted out of the match (every
   branch starting with a lambda would be), and neither lambda
   eta-reduces to [add]. *)
Fixpoint add (m n : nat) : nat := match m with O => n | S m' => S (add m' n) end.
Inductive tri := TA | TB | TC.
Definition let_match_arity (t : tri) (n : nat) : nat :=
  let f := match t with
           | TA => add
           | TB => fun x => add (S x)
           | TC => fun x y => add y x
           end
  in f (f n n) n.

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

(* 2d. The value is itself a [let] whose value is an applied fix: the
   printer substitutes it into the body and re-prints the body in the
   same position, which keeps the treatment of 2b. The fix is only
   applied at a typed argument position: a local fix at an [Object]
   position (a lambda body, a branch of this match) is a separate
   limitation, the helper's result type being inferred from there. *)
Definition let_fix_match (b : bool) (n : nat) : nat :=
  let f :=
    let g := (fix plus (m k : nat) : nat :=
                match m with O => k | S m' => S (plus m' k) end) n in
    match b with true => succ | false => fun x => succ (g (S n)) end
  in f (f n).

Extraction "java_lambda_object_target.java"
  use_pair_fun let_fun let_match let_match_arity let_fix_match
  apply_idf over_idf use_pair_id.
