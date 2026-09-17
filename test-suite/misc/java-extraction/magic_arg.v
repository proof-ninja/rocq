Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/magic_arg".

Inductive nat : Set := O : nat | S : nat -> nat.
Inductive bool : Set := true : bool | false : bool.

Fixpoint add (n m : nat) : nat :=
  match n with O => m | S p => S (add p m) end.

Definition dep (b : bool) : (if b then nat else bool) :=
  match b return (if b then nat else bool) with
  | true => S O
  | false => false
  end.

(* Same magic-producing dependent match as magic_cons.v/magic_apply.v ([dep]'s
   Java type erases to Object because its branches don't unify), but here the
   magic'd branch body is `add (dep true) O` -- a fully applied, ordinary
   global function ([add : nat -> nat -> nat], no magic of its own) fed the
   dependent value as its FIRST argument, inside the branch that produces it.
   extraction.ml's [extract_cst_app] for that inner "add (dep true) O" call
   computes two independent magics: [magic1], when the reconstructed
   application type doesn't unify with [add]'s own schema (false here --
   [add] gets exactly its two arguments), and [magic2], when the *result*
   type disagrees with the surrounding context (true here, since the
   dependent match's own branch type is Tunknown). With [magic1] false,
   [put_magic_if (magic2 && not magic1) (mlapp head mla)] wraps the WHOLE
   call in one magic; mlutil.ml's [simpl] then pushes it onto the head
   ([MLmagic(MLapp(f,l)) -> MLapp(MLmagic f, l)]), landing exactly on
   [type_of_expr]'s [MLmagic] case (java.ml) -- but this time the callee
   under the magic is [add] itself, whose Java type is fully concrete
   (Function<nat, Function<nat, nat>>), unlike magic_let.v's "no case here
   demonstrated actual harm" situation (there the concrete type was never in
   reach through the magic at all). Before #39's fix, [type_of_expr]
   unconditionally answered "unknown" for [MLmagic], so [add]'s own known
   parameter types never reached [dep true] (the first argument) as an
   argument-position cast: [add.apply(dep.apply(...))] passes an Object
   where [add]'s first parameter is nat, which javac rejects. Recursing
   through MLmagic recovers [add]'s parameter types the same way [pp_expr]'s
   own MLmagic case already recovers them for printing the call itself, and
   the missing cast reappears. *)
Definition dep2 (b : bool) : (if b then nat else bool) :=
  match b return (if b then nat else bool) with
  | true => add (dep true) O
  | false => false
  end.

Definition result : nat := dep2 true.

Extraction "java_magic_arg.java" result.
