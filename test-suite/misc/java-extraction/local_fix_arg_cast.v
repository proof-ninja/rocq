Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/local_fix_arg_cast".

Inductive nat := O : nat | S : nat -> nat.

Inductive duo (A : Type) := Duo : A -> A -> duo A.
Arguments Duo {A}.

(* Polymorphic accessors: their results are [Object] in Java. *)
Definition dfst {A : Type} (d : duo A) : A := match d with Duo x _ => x end.
Definition dsnd {A : Type} (d : duo A) : A := match d with Duo _ y => y end.
Definition ifst {A : Type} (d : duo A) : A := match d with Duo x _ => x end.
Definition isnd {A : Type} (d : duo A) : A := match d with Duo _ y => y end.
Extraction Inline ifst isnd.

(* A local fix applied to all its parameters is given the function type its
   application determines: a parameter whose argument is [Object] (the
   field of a [duo nat] read by an inlined accessor, a call to a
   polymorphic accessor) is at [Object], and is cast where it meets [nat]
   in the body. Without this the [fix2] helper's type arguments were
   inferred from the [Object] arguments and clashed with the result type,
   failing javac (#35). *)

(* #35's reproduction: the arguments are inlined accessors. *)
Definition duo_sum (d : duo nat) : nat :=
  (fix add (m n : nat) : nat := match m with O => n | S m' => S (add m' n) end)
    (ifst d) (isnd d).

(* The same through the accessors themselves. *)
Definition duo_sum' (d : duo nat) : nat :=
  (fix add (m n : nat) : nat := match m with O => n | S m' => S (add m' n) end)
    (dfst d) (dsnd d).

Definition double (n : nat) : nat :=
  (fix dbl (n : nat) : nat := match n with O => O | S n' => S (S (dbl n')) end) n.

(* A parameter at [Object] passed to a top-level function and stored in a
   constructor field. *)
Definition duo_mix (d : duo nat) : nat :=
  (fix go (m acc : nat) : nat :=
     match m with O => double acc | S m' => go m' (S acc) end)
    (dfst d) (isnd d).

Extraction "java_local_fix_arg_cast.java" duo_sum duo_sum' duo_mix.
