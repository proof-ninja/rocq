Require Corelib.extraction.Extraction.
Require Corelib.Floats.FloatClass.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/module_alias_module".

(* Requesting an alias module as a whole. The request is a module path,
   not a reference, so it cannot be redirected to the canonical name;
   instead every alias block that is dropped adds its canonical block to
   the objects to appear. [FloatClass] declares nothing but the inductive,
   so nothing else would keep that block alive. *)
Module FC := Corelib.Floats.FloatClass.

Extraction "java_module_alias_module.java" FC.
