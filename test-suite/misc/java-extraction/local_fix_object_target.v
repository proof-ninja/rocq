Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/local_fix_object_target".

Inductive nat := O : nat | S : nat -> nat.
Inductive pos := XH : pos | XO : pos -> pos.
Inductive bool := true : bool | false : bool.
Inductive prod (A B : Type) := pair : A -> B -> prod A B.
Arguments pair {A B}.

Fixpoint add (n m : nat) : nat := match n with O => m | S p => S (add p m) end.

Definition id {A : Type} (x : A) : A := x.
Extraction NoInline id.

(* A local fix applied to all its parameters at a position of static type
   [Object] (a polymorphic constructor field, a polymorphic parameter, a
   scrutinee): javac infers the result type of its [fixK] as [Object], so
   its self calls return [Object] and are cast where their results are
   used at a concrete type (#70). *)

(* #70's reproduction. *)
Definition field (n : nat) : prod bool pos :=
  pair true ((fix f (n : nat) : pos := match n with O => XH | S m => XO (f m) end) n).

Definition param (n : nat) : pos :=
  id ((fix f (n : nat) : pos := match n with O => XH | S m => XO (f m) end) n).

Definition scrut (n : nat) : nat :=
  match (fix f (n : nat) : pos := match n with O => XH | S m => XO (f m) end) n with
  | XH => O
  | XO _ => S O
  end.

(* Self calls at the arguments of a top-level function. *)
Definition twice (n : nat) : prod bool nat :=
  pair true ((fix f (n : nat) : nat :=
                match n with O => S O | S m => add (f m) (f m) end) n).

(* A self tail call ([$tfix2]) and a non-tail one, inside [$done2]. *)
Definition tail (n : nat) : prod bool nat :=
  pair true ((fix f (n acc : nat) {struct n} : nat :=
                match n with
                | O => acc
                | S m => match m with O => S (f m acc) | S p => f p (S acc) end
                end) n O).

(* A local fix in the argument of a self call of another one: its target
   is the parameter javac inferred, not [Object], so it is printed as
   before (no cast needed); a guard against typing it at [Object]. *)
Definition in_arg (n : nat) : prod bool nat :=
  pair true ((fix d (n x : nat) {struct n} : nat :=
                match n with
                | O => x
                | S m => d m ((fix a (k : nat) : nat :=
                                 match k with O => O | S j => S (a j) end) (S x))
                end) n O).

(* A local fix in the body of another one, its result used at [nat]. *)
Definition in_body (n : nat) : prod bool nat :=
  pair true ((fix d (n : nat) : nat :=
                match n with
                | O => O
                | S m => add (d m) ((fix a (k : nat) : nat :=
                                       match k with O => S O | S j => S (a j) end) m)
                end) n).

(* A local fix in tail position of another one at [Object]: printed the
   same way, its self calls cast too. *)
Definition in_tail (n : nat) : prod bool nat :=
  pair true ((fix d (n : nat) : nat :=
                match n with
                | O => O
                | S m => (fix a (k : nat) : nat :=
                            match k with O => d m | S j => S (a j) end) m
                end) n).

Definition idn (r : nat) : nat := r.
Extraction NoInline idn.

(* A lambda passed to a self call: the parameter keeps the type javac
   infers from the argument ([idn]'s), at [Object] and at a concrete
   position, so the lambda is typed by it, uncast. A guard against
   typing the parameters (no cast is needed here). *)
Definition cps_object (n : nat) : prod bool nat :=
  pair true ((fix f (n : nat) (k : nat -> nat) {struct n} : nat :=
                match n with O => k O | S m => f m (fun r => k (S (S r))) end)
               n idn).

Definition cps (n : nat) : nat :=
  (fix f (n : nat) (k : nat -> nat) {struct n} : nat :=
     match n with O => k O | S m => f m (fun r => k (S (S r))) end) n idn.

(* A result type depending on the argument. *)
Fixpoint tower (n : nat) : Type :=
  match n with O => nat | S m => prod nat (tower m) end.

Definition depth (n : nat) : prod bool (tower n) :=
  pair true ((fix f (n : nat) : tower n :=
                match n return tower n with
                | O => O
                | S m => pair (match m return tower m -> nat with
                               | O => fun x => S x
                               | S _ => fun _ => O
                               end (f m)) (f m)
                end) n).

(* A catch-all branch on a local fix's result binds a variable at
   [Object], cast where it is used at a concrete type. *)
Inductive tri := T1 : tri | T2 : tri | T3 : nat -> tri.

Definition tri_rank (p : tri) : nat := match p with T1 => O | _ => S O end.
Extraction NoInline tri_rank.

Definition catch_all (n : nat) : nat :=
  match (fix f (n : nat) : tri :=
           match n with O => T1 | S m => match f m with T1 => T2 | _ => T3 m end end) n with
  | T1 => S (S O)
  | p => tri_rank p
  end.

(* A function-valued result, and the fix passed as a value. *)
Definition fun_result (n : nat) : prod bool (nat -> nat) :=
  pair true ((fix f (n : nat) : nat -> nat :=
                match n with O => fun x => x | S m => let g := f m in fun x => S (g x) end) n).

Definition app_pos (h : nat -> pos) (n : nat) : pos := h n.
Extraction NoInline app_pos.

Definition self_value (n : nat) : prod bool pos :=
  pair true ((fix f (n : nat) : pos := match n with O => XH | S m => XO (app_pos f m) end) n).

Definition self_partial (n : nat) : prod bool pos :=
  pair true ((fix f (n acc : nat) {struct n} : pos :=
                match n with O => XH | S m => XO (app_pos (f m) acc) end) n O).

(* A scrutinee whose arguments are all at [Object]: put at [Object] as a
   whole (#35), then its self calls are cast as well. *)
Definition scrut_object (n : nat) : nat :=
  match (fix f (n : nat) : pos := match n with O => XH | S m => XO (f m) end) (id n) with
  | XH => O
  | XO _ => S O
  end.

Extraction "java_local_fix_object_target.java"
  field param scrut twice tail in_arg in_body in_tail cps_object cps depth
  catch_all fun_result self_value
  self_partial scrut_object.
