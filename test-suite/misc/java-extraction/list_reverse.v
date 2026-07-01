Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/list_reverse".

Inductive natlist :=
| Nil : natlist
| Cons : nat -> natlist -> natlist.

Fixpoint app (l1 l2 : natlist) : natlist :=
  match l1 with
  | Nil => l2
  | Cons x xs => Cons x (app xs l2)
  end.

Fixpoint reverse (l : natlist) : natlist :=
  match l with
  | Nil => Nil
  | Cons x xs => app (reverse xs) (Cons x Nil)
  end.

Extraction "java_list_reverse.java"
  reverse.
