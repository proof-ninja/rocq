Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/mono_branch_lam".

Inductive nat : Set := O : nat | S : nat -> nat.
Inductive bool : Set := true : bool | false : bool.

(* Regression lock for the case cedretaber's review on PR #40 found: a
   monomorphic match (no MLmagic anywhere) with a branch that prints as a
   bare lambda. [permut_case_fun] (mlutil.ml) lifts a match's branches out
   past a shared minimum of lambdas, but when one branch is a bare global
   reference (zero lambdas, as [g] is here), that minimum is zero and the
   lift is skipped -- the other branch's lambda is left sitting inside the
   match, in [cast_branch_lambda]'s ternary-branch position, exactly as
   in the MLmagic cases this file's other magic_*.v tests exercise. Unlike
   those, [pick]'s own type is fully known ([bool -> nat -> nat]), so
   [expected] here is never [Object] -- the branch must print with the same
   argument type ([nat]) [MLlam]'s own [peel_lams] would assign it, not
   wrapped in a needless [Function<Object, Object>] cast. *)
Definition g (x : nat) : nat := x.
Definition pick (b : bool) : nat -> nat :=
  match b with
  | true => fun x => S x
  | false => g
  end.
Definition use_pick : nat := pick true O.

Extraction "java_mono_branch_lam.java" use_pick.
