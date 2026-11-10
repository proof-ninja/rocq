Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/tail_dfix".

Inductive nat : Set :=
| O : nat
| S : nat -> nat.

Inductive natlist : Set :=
| Nil : natlist
| Cons : nat -> natlist -> natlist.

(* A self tail call: the body is wrapped in [$loop2] and runs in constant
   Java stack, so the driver can pass a list far deeper than the stack. *)
Fixpoint rev_append (l acc : natlist) : natlist :=
  match l with
  | Nil => acc
  | Cons x xs => rev_append xs (Cons x acc)
  end.

Fixpoint length_acc (l : natlist) (n : nat) : nat :=
  match l with
  | Nil => n
  | Cons _ xs => length_acc xs (S n)
  end.

(* Tail and non-tail self calls mixed; the tail call sits in a nested match,
   under the binders of both branches. *)
Fixpoint mixed (l : natlist) (acc : nat) : nat :=
  match l with
  | Nil => acc
  | Cons O xs => mixed xs (S acc)
  | Cons (S _) xs => S (mixed xs acc)
  end.

(* A tail call with a lambda argument: [$next3] gives it its target type. *)
Fixpoint iter (f : nat -> nat) (l : natlist) (x : nat) : nat :=
  match l with
  | Nil => x
  | Cons _ xs => iter (fun y => S (f y)) xs (f x)
  end.

(* The result type is an alias of a function type: its expansion supplies
   the arrows for the second lambda. *)
Definition endo := nat -> nat.

Fixpoint add_acc (n : nat) : endo :=
  fun m => match n with
           | O => m
           | S p => add_acc p (S m)
           end.

(* No self tail call: printed as before, without a loop. *)
Fixpoint add (n m : nat) : nat :=
  match n with
  | O => m
  | S p => S (add p m)
  end.

Extraction "java_tail_dfix.java"
  rev_append length_acc mixed iter add_acc add.
