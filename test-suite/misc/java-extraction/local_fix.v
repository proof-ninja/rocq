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

Extraction "java_local_fix.java"
  rev_acc rev_pair.
