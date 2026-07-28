Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/fix0".

Inductive natlist :=
| Nil : natlist
| Cons : nat -> natlist -> natlist.

Inductive mode :=
| Reverse : mode
| Keep : mode.

Fixpoint app (l1 l2 : natlist) : natlist :=
  match l1 with
  | Nil => l2
  | Cons x xs => Cons x (app xs l2)
  end.

(* The local fix is handed back as a bare value from a match branch: at that
   print site no argument is applied yet, so [pp_fix] gets [args = []] and
   emits [fix0]. The [Keep] branch keeps the match from being reducible and
   contrasts a global function in the same position. *)
Definition rev_selector (m : mode) : natlist -> natlist -> natlist :=
  let fix go (l acc : natlist) : natlist :=
    match l with
    | Nil => acc
    | Cons x xs => go xs (Cons x acc)
    end
  in
  match m with
  | Reverse => go
  | Keep => app
  end.

(* [iterate] is a top-level Fixpoint, so extraction never auto-inlines it.
   The local fix therefore stays an unapplied argument and prints as [fix0]
   again, this time in argument position. *)
Fixpoint iterate (f : natlist -> natlist -> natlist) (n : nat) (l : natlist)
  : natlist :=
  match n with
  | O => l
  | S k => iterate f k (f l Nil)
  end.

Definition rev_iterated (n : nat) (input : natlist) : natlist :=
  let fix go (l acc : natlist) : natlist :=
    match l with
    | Nil => acc
    | Cons x xs => go xs (Cons x acc)
    end
  in iterate go n input.

Extraction "java_fix0.java"
  rev_selector rev_iterated.
