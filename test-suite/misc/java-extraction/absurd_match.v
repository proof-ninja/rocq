Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/absurd_match".

Inductive empty : Set := .

Inductive result :=
| Ok : result
| Ng : result.

(* [shape] wraps [empty] so that the extracted lambda still uses its
   parameter: matching a parameter directly against an empty inductive would
   leave the parameter unused and extract it as the dummy binder [_], which
   is not a valid lambda parameter name on every supported JDK. *)
Inductive shape :=
| Leaf : shape
| Wrap : empty -> shape.

Definition from_shape (s : shape) : result :=
  match s with
  | Leaf => Ok
  | Wrap e => match e with end
  end.

Extraction "java_absurd_match.java"
  from_shape.
