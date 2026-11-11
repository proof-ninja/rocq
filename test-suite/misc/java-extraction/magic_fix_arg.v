Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/magic_fix_arg".

Inductive nat : Set := O : nat | S : nat -> nat.
Inductive bool : Set := true : bool | false : bool.

Definition dep (b : bool) : (if b then nat else bool) :=
  match b return (if b then nat else bool) with
  | true => S O
  | false => false
  end.

(* [dep true] (a plain MLglob application, needing no magic itself) is fed
   as an ARGUMENT to a genuinely local fix -- structurally the same shape as
   issue #14 sub-issue #35 (a value with no cast reaching a fixK helper's
   argument position), except that here the value comes from a dependent
   match rather than an inlined polymorphic accessor. Unlike #35's repro,
   this one is not blocked by javac: fixK's type parameters are inferred as
   Object here (harmlessly, since the local fix only ever uses [m] via
   instanceof/let, never as a fixed concrete type), so this documents that
   MLmagic itself is not what breaks #35 -- kept as a regression lock, not
   as a demonstration that MLmagic needed a fixK-side fix. *)
Definition combine (n : nat) : nat :=
  (fix add (m n : nat) : nat := match m with O => n | S m' => S (add m' n) end)
    (dep true) n.

Definition result : nat := combine (S O).

Extraction "java_magic_fix_arg.java" result.
