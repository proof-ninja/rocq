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

(* A local fix applied to all its parameters, one of its arguments at
   [Object] (the field of a [duo nat] read by an inlined accessor, a call
   to a polymorphic accessor), is put at [Object] as a whole: its
   parameters and result are at [Object] and cast where the body uses them
   at [nat], its arguments are cast up to [Object], and the result is cast
   back to [nat]. Without this the [fix2] helper's type arguments were
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
   different iterations: [x] is first a [bool], then [g O = S O], read
   back at [nat]. At [Object] it needs no cast but where its type is
   known. *)
Definition dep_arg (d : duo bool) : nat :=
  (fix f (n : nat) (x : F n) {struct n} : nat :=
     match n return F n -> nat with
     | O => fun x => S x
     | S n' => fun _ => f n' (g n')
     end x) (S (S O)) (dfst d).

(* A lambda argument casts itself to its function type before the cast up
   to [Object]; the body casts the parameter back to apply it. *)
Definition lam_arg (d : duo nat) : nat :=
  (fix go (p : nat -> nat) (n : nat) {struct n} : nat :=
     match n with O => p O | S n' => S (go p n') end)
    (fun x => S x) (dfst d).

Definition app1 (h : nat -> nat) (y : nat) : nat := h y.

(* No argument at [Object]: printed as before, even though the fix
   escapes. *)
Definition escape (m : nat) : nat :=
  (fix f (n acc : nat) {struct n} : nat :=
     match n with O => acc | S n' => app1 (f n') (S acc) end) m O.

Extraction "java_local_fix_arg_cast.java"
  duo_sum duo_sum' duo_mix dep_arg lam_arg escape.
