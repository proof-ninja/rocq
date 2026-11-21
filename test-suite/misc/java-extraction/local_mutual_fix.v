Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/local_mutual_fix".

Inductive nat := O : nat | S : nat -> nat.
Inductive bool := true : bool | false : bool.

Fixpoint add (n m : nat) : nat := match n with O => m | S p => S (add p m) end.

(* Applies its argument, so that a member is passed unapplied. *)
Definition app (p : nat -> bool) (x : nat) : bool := p x.
Extraction NoInline app.

(* Section variables turn mutual [Fixpoint]s into local mutual fixes:
   [even] is [fun b => fix even ... with odd ... for even], and [odd] the
   same fix for [odd]. *)
Section Parity.
  Variable b : bool.

  Fixpoint even (n : nat) : bool :=
    match n with O => b | S m => odd m end
  with odd (n : nat) : bool :=
    match n with O => match b with true => false | false => true end
            | S m => even m end.
End Parity.

(* Three members of different types and arities. [f] has a self tail call;
   [g] matches on the result of a call to [f]; [h] passes [g] unapplied; the
   partners are called under match binders. *)
Section Three.
  Variable k : nat.

  Fixpoint f (n acc : nat) : nat :=
    match n with
    | O => add k acc
    | S m => match g m with true => f m (S acc) | false => h true m acc end
    end
  with g (n : nat) : bool :=
    match n with
    | O => true
    | S m => match f m O with O => false | S O => true | S (S p) => even true p end
    end
  with h (c : bool) (n acc : nat) : nat :=
    match n with
    | O => acc
    | S m => match c with
             | true => f m (S (S acc))
             | false => match app g m with true => h c m (S acc) | false => h c m acc end
             end
    end.
End Three.

(* Four members, with free variables at two depths: [x] and [y] bound by
   lambdas, [z] by a [let]. Selecting the first and the last member. *)
Definition four (x y : nat) : nat -> nat :=
  let z := add x y in
  fix a (n : nat) : nat := match n with O => z | S m => b m end
  with b (n : nat) : nat := match n with O => x | S m => add y (c m) end
  with c (n : nat) : nat := match n with O => y | S m => d m z end
  with d (n r : nat) : nat :=
    match n with O => add r z | S m => match a m with O => b m | S _ => add r (c m) end end
  for a.

Definition four_d (x y : nat) : nat -> nat -> nat :=
  let z := add x y in
  fix a (n : nat) : nat := match n with O => z | S m => b m end
  with b (n : nat) : nat := match n with O => x | S m => add y (c m) end
  with c (n : nat) : nat := match n with O => y | S m => d m z end
  with d (n r : nat) : nat :=
    match n with O => add r z | S m => match a m with O => b m | S _ => add r (c m) end end
  for d.

(* A local mutual fix in the body of a top-level mutual fixpoint. *)
Fixpoint top1 (n : nat) : nat :=
  match n with
  | O => O
  | S m =>
      (fix p (k : nat) : nat := match k with O => top2 m | S j => q j end
       with q (k : nat) : nat := match k with O => m | S j => p j end
       for q) m
  end
with top2 (n : nat) : nat := match n with O => S O | S m => top1 m end.

Extraction "java_local_mutual_fix.java" even odd f g h four four_d top1 top2.
