Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/match_default".

Inductive color :=
| Red : color
| Green : color
| Blue : color.

(* The shared default branch factorizes to a Pwild catch-all: its body does
   not use the matched value. *)
Definition default_to_red (c : color) : color :=
  match c with
  | Red => Green
  | _ => Red
  end.

(* The scrutinee is a compound expression and the default branch uses the
   matched value, so it factorizes to a Prel catch-all binding the scrutinee
   to a variable. *)
Definition normalize (c : color) : color :=
  match default_to_red c with
  | Red => Green
  | other => other
  end.

Extraction "java_match_default.java"
  default_to_red normalize.
