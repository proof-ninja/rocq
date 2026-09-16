Require Corelib.extraction.Extraction.
Require Corelib.Floats.FloatClass.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/module_alias_direct".

Inductive nat := O : nat | S : nat -> nat.

Module Other.
  Inductive point := P : nat -> nat -> point.
  Record rec : Type := MkRec { rx : nat; ry : nat }.
End Other.

Module M := Other.

(* Requesting an inductive (or a constructor) directly by its alias name.
   The Java printer declares the block only under its canonical name, so
   the request has to be redirected there as well: for the toplevel
   [Extraction] the declaration must be found in the extracted structure
   (an anomaly otherwise; only the absence of that anomaly is checked,
   the printed text is not compared), and for [Extraction "file"] the
   requested name is the seed of dead-code removal. *)
Extraction M.point.
Extraction M.P.
Extraction M.rec.

(* [FloatClass] declares an inductive and nothing that refers to it, so
   with the alias name as seed the canonical block (which lives at the
   toplevel of another file) has nothing else keeping it alive. *)
Module FC := Corelib.Floats.FloatClass.

Extraction "java_module_alias_direct.java" M.point M.rec FC.float_class.
