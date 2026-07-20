Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/axiom".

Inductive value :=
| A : value
| B : value.

Axiom mystery : value.

Extraction "java_axiom.java"
  mystery.
