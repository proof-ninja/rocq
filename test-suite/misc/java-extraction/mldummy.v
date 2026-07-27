Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/mldummy".

(* Logical (Prop) constants survive extraction as [MLdummy] when extracted
   directly: they must become a benign value, not a throwing expression. *)

Definition tt_prop : True := I.

Definition both : True /\ True := conj I I.

Extraction "java_mldummy.java"
  tt_prop both.
