Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/type_custom".

(* Custom extraction of a type: Java has no type-alias declaration, so the
   custom string is printed at every type position instead of a name.
   Writing a string that is valid Java is the user's responsibility. *)
Axiom big : Type.
Extract Constant big => "java.math.BigInteger".

Axiom zero_big : big.
Extract Constant zero_big => "java.math.BigInteger.ZERO".

Axiom inc_big : big -> big.
Extract Constant inc_big => "b -> b.add(java.math.BigInteger.ONE)".

Definition inc2 (b : big) : big := inc_big (inc_big b).

(* A synonym of a custom type: the alias expands to the custom type, whose
   printing falls back to the custom string. *)
Definition big2 := big.
Definition inc2b (b : big2) : big2 := inc2 b.

Extraction "java_type_custom.java" inc2 inc2b zero_big.
