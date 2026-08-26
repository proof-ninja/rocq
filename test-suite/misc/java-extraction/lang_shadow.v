Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/lang_shadow".

(* Names that collide with the java.lang/java.util types the generated code
   references by simple name (String, Object, Function, RuntimeException,
   SuppressWarnings). Without renaming, such a nested class shadows the real
   type throughout the wrapper class: e.g. a constructor [String] (the shape
   of Stdlib's string type) breaks the [error(String msg)] helper. *)

(* Mirrors Stdlib's string. *)
Inductive ascii := Dot | Dash.
Inductive string := EmptyString | String : ascii -> string -> string.
Definition dot_prefix (s : string) : string := String Dot s.

(* The remaining reserved names as constructors: each becomes a nested
   class, so each must be renamed. *)
Inductive lang :=
| Function : lang
| RuntimeException : lang
| SuppressWarnings : lang
| Object : lang.
Definition rotate (o : lang) : lang :=
  match o with
  | Function => RuntimeException
  | RuntimeException => SuppressWarnings
  | SuppressWarnings => Object
  | Object => Function
  end.

Extraction "java_lang_shadow.java" dot_prefix rotate.
