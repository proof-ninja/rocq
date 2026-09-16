Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/prime_names".

(* Rocq names use ['] freely (n', IHn', t'); a Java identifier cannot contain
   it. Local binders were already mapped to [$] by [pr_id], but global names
   went out verbatim and stopped javac at the lexer. Every kind of global name
   is covered here: a type, its constructors (declared, constructed and
   matched on), and constants. Two constructors keep [t'] away from the
   singleton scheme, whose casts do not survive class loading. *)

Inductive nat := O | S : nat -> nat.

Inductive t' := C' : nat -> t' | D' : t'.

Definition succ' (n : nat) : nat := S n.

Definition build' (n : nat) : t' := C' (succ' n).

(* [n'] is a local binder: the path that already worked. *)
Definition unwrap' (x : t') : nat :=
  match x with
  | C' n' => n'
  | D' => O
  end.

Extraction "java_prime_names.java" build' unwrap'.
