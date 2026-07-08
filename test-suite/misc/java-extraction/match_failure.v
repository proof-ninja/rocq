Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/match_failure".

Inductive color :=
| Red : color
| Green : color
| Blue : color.

Definition rotate (c : color) : color :=
  match c with
  | Red => Green
  | Green => Blue
  | Blue => Red
  end.

Extraction "java_match_failure.java"
  rotate.
