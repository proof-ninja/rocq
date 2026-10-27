Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/tail_local_fix".

Inductive nat : Set :=
| O : nat
| S : nat -> nat.

Inductive natlist : Set :=
| Nil : natlist
| Cons : nat -> natlist -> natlist.

(* The fix is applied to a constructor, not just to the lambda variables, so
   Mlutil.optimize_fix cannot hoist it into a top-level Dfix: it stays a
   local fix applied to as many arguments as it has lambdas, and is printed
   with [$tfix2]. *)
Definition length (l : natlist) : nat :=
  let fix go (l : natlist) (n : nat) : nat :=
    match l with
    | Nil => n
    | Cons _ xs => go xs (S n)
    end
  in go l O.

(* The tail call sits under a [let]. *)
Definition count_zeros (l : natlist) : nat :=
  let fix go (l : natlist) (n : nat) : nat :=
    match l with
    | Nil => n
    | Cons x xs =>
        let n' := match x with O => S n | S _ => n end in
        go xs n'
    end
  in go l O.

(* Applied to fewer arguments than it has lambdas: stays [fix1]. *)
Definition rev_onto : natlist -> natlist :=
  let fix go (acc l : natlist) : natlist :=
    match l with
    | Nil => acc
    | Cons x xs => go (Cons x acc) xs
    end
  in go Nil.

Extraction "java_tail_local_fix.java"
  length count_zeros rev_onto.
