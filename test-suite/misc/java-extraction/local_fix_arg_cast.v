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

(* A local fix applied to all its parameters, all its arguments at
   [Object] (fields of a [duo nat] read by inlined accessors, calls to
   polymorphic accessors), is put at [Object] as a whole: its parameters
   and result are at [Object] and cast where the body uses them at [nat],
   and the result is cast back to [nat]. Without this the [fix2] helper's
   type arguments were inferred from the [Object] arguments and clashed
   with the result type, failing javac (#35). *)

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

Definition app1 (h : nat -> nat) (y : nat) : nat := h y.

(* Arguments not at [Object]: printed as any other local fix. *)
Definition escape (m : nat) : nat :=
  (fix f (n acc : nat) {struct n} : nat :=
     match n with O => acc | S n' => app1 (f n') (S acc) end) m O.

Extraction "java_local_fix_arg_cast.java"
  duo_sum duo_sum' duo_mix escape.
