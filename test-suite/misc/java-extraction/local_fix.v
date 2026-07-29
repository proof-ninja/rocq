Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/local_fix".

Inductive natlist :=
| Nil : natlist
| Cons : nat -> natlist -> natlist.

Definition rev_acc (l acc : natlist) : natlist :=
  let fix go l acc :=
    match l with
    | Nil => acc
    | Cons x xs => go xs (Cons x acc)
    end
  in go l acc.

Definition rev_pair (l : natlist) : natlist :=
  let fix go l acc :=
    match l with
    | Nil => acc
    | Cons x xs => go xs (Cons x acc)
    end
  in go (go l Nil) Nil.

(* Exactly one argument is applied at this call site, so [pp_fix] gets
   [args] of length 1 and emits [fix1]. The let-body has no leading lambda,
   so Mlutil.optimize_fix returns immediately and the fix cannot be hoisted
   into a top-level Dfix the way [rev_acc] is. *)
Definition rev_onto : natlist -> natlist :=
  let fix go (acc l : natlist) : natlist :=
    match l with
    | Nil => acc
    | Cons x xs => go (Cons x acc) xs
    end
  in go Nil.

Extraction "java_local_fix.java"
  rev_acc rev_pair rev_onto.
