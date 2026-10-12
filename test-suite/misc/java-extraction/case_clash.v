Require Corelib.extraction.Extraction.

Extraction Language Java.
Set Extraction Output Directory "misc/java-extraction/_generated/case_clash".

(* javac writes every nested class to its own [Outer$Inner.class] file, so the
   classes of a same scope must differ by more than case. *)

(* A type and its own constructor: the constructor class is nested in the
   type's class, so neither is renamed. *)
Inductive ascii := Ascii : bool -> bool -> ascii.

Definition ascii_fst (a : ascii) : bool :=
  match a with Ascii b _ => b end.

(* Constructors of distinct types: nested in distinct classes, not renamed. *)
Inductive p := Leaf | Node.
Inductive q := LEAF | NODE.

Definition p_to_q (x : p) : q :=
  match x with Leaf => LEAF | Node => NODE end.

(* Types differing only in case: the second one is renamed. *)
Inductive fooBar := FB1 | FB2.
Inductive foobar := Fb : fooBar -> foobar | NoFb.

Definition wrap (x : fooBar) : foobar := Fb x.

Definition unwrap (x : foobar) : fooBar :=
  match x with Fb y => y | NoFb => FB1 end.

(* Constructors of a same type differing only in case: the second one is
   renamed. *)
Inductive ab := Ab | AB.

Definition flip (x : ab) : ab := match x with Ab => AB | AB => Ab end.

(* A type named like the top-level class: renamed, as Java forbids a nested
   class to share the simple name of an enclosing one. *)
Inductive java_case_clash := Clash : ab -> java_case_clash | NoClash.

Definition clash_flip (x : java_case_clash) : java_case_clash :=
  match x with Clash y => Clash (flip y) | NoClash => NoClash end.

Extraction "java_case_clash.java"
  ascii_fst p_to_q wrap unwrap flip clash_flip.
