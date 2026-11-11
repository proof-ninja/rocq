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

Inductive bool := true : bool | false : bool.

Definition F (n : nat) : Set := match n with O => nat | S _ => bool end.
Definition g (n : nat) : F n := match n return F n with O => S O | S _ => true end.

(* A parameter of a dependent type takes values of different Java types on
   different iterations: [x] is first a [bool], then [g O = S O]. Typing it
   from the first argument would cast the self call's argument to [bool],
   failing at run time, so the self calls that do not agree with it set it
   back to [Object], and the first argument is cast up to [Object] so that
   javac does not infer [fix2]'s type argument from it. [n] keeps [nat]. *)
Definition dep_arg : nat :=
  (fix f (n : nat) (x : F n) {struct n} : nat :=
     match n with O => O | S n' => f n' (g n') end) (S (S O)) true.

(* The same, reading [x] back at [nat] where its type is known to be. *)
Definition dep_arg_read : nat :=
  (fix f (n : nat) (x : F n) {struct n} : nat :=
     match n return F n -> nat with
     | O => fun x => S x
     | S n' => fun _ => f n' (g n')
     end x) (S (S O)) true.

Definition app1 (h : nat -> nat) (y : nat) : nat := h y.

(* A fix used other than in a call with all its arguments could be passed
   anything, so all its parameters are at [Object]. *)
Definition escape (m : nat) : nat :=
  (fix f (n acc : nat) {struct n} : nat :=
     match n with O => acc | S n' => app1 (f n') (S acc) end) m O.

Extraction "java_local_fix_arg_cast.java"
  duo_sum duo_sum' duo_mix dep_arg dep_arg_read escape.
