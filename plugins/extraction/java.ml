(************************************************************************)
(*         ymoymoon         *)
(************************************************************************)

(*s Production of Java syntax. *)

open Pp
open CErrors
open Util
open Names
open Table
open Miniml
open Mlutil
open Common

(*s Java renaming issues. *)
let keywords =
  List.fold_right (fun s -> Id.Set.add (Id.of_string s))
    [ "abstract"; "continue"; "for"; "new"; "switch";
    "assert"; "default"; "if"; "package"; "synchronized";
    "boolean"; "do"; "goto"; "private"; "this";
    "break";  "double"; "implements"; "protected"; "throw";
    "byte"; "else"; "import"; "public"; "throws";
    "case"; "enum"; "instanceof"; "return"; "transient";
    "catch"; "extends"; "int"; "short"; "try";
    "char"; "final"; "interface"; "static"; "void";
    "class"; "finally"; "long"; "strictfp"; "volatile";
    "const"; "float"; "native"; "super"; "while"; "_";
    (* not Java keywords, but names of the generated [class Main] helpers:
       reserve them so extracted identifiers get renamed instead of clashing *)
    "let"; "error"; "__"; "__dummy" ]
    Id.Set.empty

let pp_comment s = str "// " ++ s ++ fnl ()
let pp_header_comment = function
  | None -> mt ()
  | Some com -> pp_comment com ++ fnl () ++ fnl ()

let preamble _ _ comment _ _ =
  pp_header_comment comment ++
  str "import java.util.function.Function;" ++ fnl() ++ fnl()

let comma = fun _ -> str ", "
let paren = pp_par true

(* Prints [s] as a Java string literal. [Pp.qs] escapes for OCaml, whose
   conventions differ from Java's (e.g. decimal [\255] escapes).
   Note: [\uXXXX] escapes are translated before Java lexes the file (JLS 3.3),
   so line terminators, quotes and backslashes must be handled by the explicit
   cases below and never reach the [\u] fallback. *)
let pp_java_string s =
  let buf = Buffer.create (String.length s + 2) in
  Buffer.add_char buf '"';
  String.iter (fun c -> match c with
    | '"'  -> Buffer.add_string buf {|\"|}
    | '\\' -> Buffer.add_string buf {|\\|}
    | '\n' -> Buffer.add_string buf {|\n|}
    | '\r' -> Buffer.add_string buf {|\r|}
    | '\t' -> Buffer.add_string buf {|\t|}
    | c when Char.code c < 0x20 ->
        Buffer.add_string buf (Printf.sprintf {|\u%04x|} (Char.code c))
    | c -> Buffer.add_char buf c) s;
  Buffer.add_char buf '"';
  str (Buffer.contents buf)


let pp_global table k r =
  if is_inline_custom r then str (find_custom r)
  else str (Common.pp_global table k r)

let pr_id id =
  str @@ String.map (fun c -> if c == '\'' then '$' else c) (Id.to_string id)

let pp_tvar id = str ("'" ^ Id.to_string id) (* TODO: can we use this in Java? *)

let pp_type table vl t =
  let rec pp_rec = function
    | Tmeta _ | Tvar' _ | Taxiom -> assert false
    | Tvar i -> (try pp_tvar (List.nth vl (pred i))
                 with Failure _ -> (str "'a" ++ int i))
    | Tglob (r,[]) -> pp_global table Type r
    | Tglob (gr,l)
        when not (keep_singleton ()) && Rocqlib.check_ref sig_type_name gr.glob ->
        pp_tuple pp_rec l
    | Tglob (r,l) ->
        pp_tuple pp_rec l ++ spc () ++ pp_global table Type r
    | Tarr (t1,t2) ->
        str "Function<" ++ pp_rec t1 ++ str ", " ++ pp_rec t2++ str ">"
    (* Both stand for "no informative type here"; [Object] is the weakest
       valid Java type. A finer strategy (generics) is future work. *)
    | Tdummy _ -> str "Object"
    | Tunknown -> str "Object"
  in
  hov 0 (pp_rec t)

let pp_app st args = 
  let rec pp_rec args = match args with
    | [] -> str ""
    | h::t  -> hov 0 (str ".apply" ++ paren h ++ pp_rec t)
  in
  st ++ pp_rec args

let pp_abst st idlist = match idlist with (* may need cast, "(Function<S, T>)(x -> e)" *)
  | [] -> assert false
  | _ -> (prlist_with_sep (fun _ -> str " -> ") pr_id idlist) ++ str " ->" 
    ++ spc () ++ st ++ fnl()

let pp_letin x def body = (* let(def, x -> body), where [let] is a defined function *)
  hv 0 (hv 0 (str "let" ++ paren (def ++ str ", " ++ x ++ str " ->" ++ spc() ++ hov 0 body)))

let pp_gen_pat table = function
  | Pusual r -> pp_global_name table Cons r
  | Pcons _ -> user_err Pp.(str "Cannot handle deep patterns in Java yet.")
  | Ptuple _ -> user_err Pp.(str "Cannot handle tuple patterns in Java yet.")
  | Pwild | Prel _ -> assert false (* catch-all: handled in pp_pat_branches *)

let rec pp_expr table env args =
  let apply st = pp_app st args in
  function
    | MLrel n ->
        let id = get_db_name n env in apply (pr_id id)
    | MLapp (f,args') ->
        let stl = List.map (pp_expr table env []) args' in
        pp_expr table env (stl @ args) f
    | MLlam _ as a ->
        let fl,a' = collect_lams a in (* [fl] : arguments, [a'] : body *)
        let fl,env' = push_vars (List.map id_of_mlid fl) env in
        apply (pp_abst (pp_expr table env' [] a') (List.rev fl))
    | MLletin (id,a1,a2) ->
        let i,env' = push_vars [id_of_mlid id] env in
        let pp_id = pr_id (List.hd i)
        and pp_a1 = pp_expr table env [] a1
        and pp_a2 = pp_expr table env' [] a2 in
        hv 0 (apply (pp_letin pp_id pp_a1 pp_a2))
    | MLglob r ->
        apply (pp_global table Term r)
    | MLcons (_,r,args') -> (* [r] : a name of a constructor *)
        assert (List.is_empty args);
        str "new " ++ pp_global table Cons r ++ paren (prlist_with_sep comma (pp_expr table env []) args')
    | MLtuple _ -> user_err Pp.(str "Cannot handle tuples in Java yet.")
    | MLcase (_,t, pv) ->
          pp_pat table env t pv
    | MLfix (i,ids,defs) -> 
        let ids',env' = push_vars (List.rev (Array.to_list ids)) env in
        pp_fix table env' i (Array.of_list (List.rev ids'),defs) args
    | MLexn s ->
        (* Applied arguments are dropped: [error] throws before any
           application could happen, and the surrounding context supplies the
           expected result type for the generic return. *)
        str "error" ++ paren (pp_java_string s)
    | MLdummy _ ->
        (* [__()] is a generic method, so each occurrence is target-typed by
           its context. Applied arguments are dropped, as in the OCaml
           backend: extracted code is pure, and self-application of the dummy
           only yields the dummy again, so skipping the arguments cannot
           change the result. (Emitting the application would not compile
           anyway: a receiver position is not a poly context.) *)
        str "__()"
    | MLmagic a ->
        pp_expr table env [] a
    | MLaxiom s ->
        str "error" ++ paren (pp_java_string ("AXIOM TO BE REALIZED (" ^ s ^ ")"))
    | MLuint _ -> user_err Pp.(str "Cannot handle primitive integers in Java yet.")
    | MLfloat _ -> user_err Pp.(str "Cannot handle primitive floats in Java yet.")
    | MLstring _ -> user_err Pp.(str "Cannot handle primitive strings in Java yet.")
    | MLparray _ -> user_err Pp.(str "Cannot handle persistent arrays in Java yet.")

and pp_fix table env i (ids,bl) args =
      prvect_with_sep
        (fun () -> str ";" ++ fnl() ++ str "var ")
        (fun (fi,ti) -> pr_id fi ++ str " = " ++ pp_expr table env [] ti)
        (Array.map2 (fun id b -> (id,b)) ids bl) ++
      fnl () ++
      hov 2 (str ";" ++ fnl() ++ pp_app (pr_id ids.(i)) args)

and pp_one_pat table env exp (ids,p,t) =
  (* push_vars after List.rev_map makes the head of ids' correspond to
     de Bruijn 1 (= the last constructor argument). To match constructor
     field index j (0 = first argument) we use List.rev ids'. *)
  let n = List.length ids in
  let ids', env' = push_vars (List.rev_map id_of_mlid ids) env in
  let ids_field = List.rev ids' in
  let constr = pp_gen_pat table p in
  let body = pp_expr table env' [] t in
  let cast_exp = paren (paren (str constr) ++ exp) in
  let wrapped = List.fold_right
    (fun j acc ->
      let id = List.nth ids_field j in
      (* A field bound to a dummy (unused) variable needs no binding: the body
         never refers to it, and emitting one would print the reserved Java
         identifier [_] (and collide if several fields are unused). *)
      if Id.equal id dummy_name then acc
      else
        let field = str (constr ^ string_of_int j) in
        let var   = pr_id id in
        pp_letin var (cast_exp ++ str "." ++ field) acc)
    (List.init n (fun j -> j))
    body
  in
  str constr, wrapped

(* A top-level [Pwild] or [Prel] matches unconditionally, so it cannot (and
   need not) be tested with [instanceof]: its body is the default of the
   conditional chain. [Prel] additionally binds the scrutinee to a variable. *)
and pp_catch_all_pat table env scrut (ids,p,t) =
  match p with
  | Pwild ->
      assert (List.is_empty ids);
      pp_expr table env [] t
  | Prel _ ->
      let ids', env' = push_vars (List.rev_map id_of_mlid ids) env in
      let body = pp_expr table env' [] t in
      (match ids' with
       | [id] -> pp_letin (pr_id id) scrut body
       | _ -> assert false)
  | _ -> assert false

and pp_pat table env t pv =
  let exp = pp_expr table env [] t in
  match t with
  | MLrel _ | MLglob _ ->
      (* already a simple value: safe and cheap to repeat in place *)
      pp_pat_branches table env exp pv
  | _ ->
      (* bind the scrutinee once so a complex/effectful expression is not
         re-evaluated in every [instanceof] test and field access. The name is
         reserved in the avoid-set only (not the de Bruijn list) so the branch
         bodies keep their original de Bruijn indices. *)
      let db, avoid = env in
      let scrut_id = rename_id (Id.of_string "scrutinee") avoid in
      let env = (db, Id.Set.add scrut_id avoid) in
      let scrut = pr_id scrut_id in
      pp_letin scrut exp (pp_pat_branches table env scrut pv)

(* Every constructor branch (including the last one) is guarded by an
   [instanceof] test; the chain ends with the first catch-all branch if any,
   otherwise with an explicit match-failure so that a value fitting no branch
   raises a clear error instead of an accidental ClassCastException. *)
and pp_pat_branches table env scrut pv =
  let is_catch_all (_,p,_) = match p with Pwild | Prel _ -> true | _ -> false in
  let rec split acc = function
    | [] -> List.rev acc, None
    | b :: _ when is_catch_all b -> List.rev acc, Some b (* later branches are unreachable *)
    | b :: rest -> split (b :: acc) rest
  in
  let tests, default = split [] (Array.to_list pv) in
  let pp_default = match default with
    | Some b -> pp_catch_all_pat table env scrut b
    | None -> str "error(\"non-exhaustive match\")"
  in
  prlist_strict
    (fun b ->
      let constr, body = pp_one_pat table env scrut b in
      hv 2 (paren (scrut ++ str " instanceof " ++ constr) ++ str " ? " ++ body) ++ fnl() ++ str ": ")
    tests ++
  hv 2 pp_default

(* TODO : almost all of definitions below are from ocaml.ml *)
let str_global_with_key table k key r =
  if is_inline_custom r then find_custom r else Common.pp_global_with_key table k key r

let str_global table k r = str_global_with_key table k (repr_of_r r) r

let pp_global_with_key table k key r = str (str_global_with_key table k key r)

let pp_global table k r = str (str_global table k r)

let pp_global_name table k r = str (Common.pp_global table k r)

let pp_parameters l =
  (pp_boxed_tuple pp_tvar l ++ space_if (not (List.is_empty l)))

let kn_of_ind r = let open GlobRef in match r.glob with
  | IndRef (kn,_) -> MutInd.user kn
  | _ -> assert false

let get_ind r = let open GlobRef in match r.glob with
  | IndRef _ -> r
  | ConstructRef (ind,_) -> { glob = IndRef ind; inst = r.inst }
  | _ -> assert false

let pp_one_field table r i = function
  | Some r' -> pp_global_with_key table Term (kn_of_ind (get_ind r)) r'
  | None -> pp_global table Type (get_ind r) ++ str "__" ++ int i

let pp_fields table r fields = List.map_i (pp_one_field table r) 0 fields

let pp_equiv table param_list name inst = function
  | NoEquiv, _ -> mt ()
  | Equiv kn, i ->
    let r = { glob = GlobRef.IndRef (MutInd.make1 kn, i); inst } in
    str " = " ++ pp_parameters param_list ++ pp_global table Type r
  | RenEquiv ren, _  ->
      str " = " ++ pp_parameters param_list ++ str (ren^".") ++ name

let pp_instance_var t name = str "final " ++ t ++ str " " ++ name ++ str ";" ++ fnl()
let pp_java_constructor classname ty_name_list = 
  hv 2 (classname ++ paren (prlist_with_sep (fun () -> str ", ") (fun (t, name) -> t ++ str " " ++ name) ty_name_list) ++ str " {" ++ fnl() ++
      prlist_strict (fun (_, name) -> str "this." ++ name ++ str " = " ++ name ++ str ";" ++ fnl()) ty_name_list)
    ++ str "}" ++ fnl()


(* class with one constructor *)
let pp_singleton table packet =
  let name = pp_global_name table Type packet.ip_typename_ref in
  let l = rename_tvars keywords packet.ip_vars in
  let fieldname = Id.print packet.ip_consnames.(0) in
  let ty = pp_type table l (List.hd packet.ip_types.(0)) in
  str "public static class " ++ pp_parameters l ++ name ++ str " {" ++ fnl() ++
    pp_instance_var ty fieldname ++ fnl() ++
    pp_java_constructor name [(ty, fieldname)] ++ fnl()
    ++ str "}" ++ fnl2()

(* class with two or more constructors *)
let pp_record table fields ip_equiv packet =
  let ind = packet.ip_typename_ref in
  let name = pp_global_name table Type ind in
  let fieldnames = pp_fields table ind fields in
  let l = List.combine fieldnames packet.ip_types.(0) in
  let pl = rename_tvars keywords packet.ip_vars in
  str "public static class " ++ pp_parameters pl ++ name ++ str " {" ++ fnl() ++
    prlist_strict (fun (p,t) -> pp_instance_var (pp_type table pl t) p) l ++ fnl() ++
    (* pp_equiv table pl name ind.inst ip_equiv ++ *)
    pp_java_constructor name (List.map (fun (p, t) -> (pp_type table pl t, p)) l) ++ fnl() ++
  str " } " ++ fnl2()

(* one [Inductive a := ... .] *)
let pp_one_ind table inst ip_equiv pl name cnames ctyps =
  let pl = rename_tvars keywords pl in
  let pp_constructor i typs =
    hv 2 (str "public static class " ++ cnames.(i) ++ str " implements " ++ name ++ str " {" ++ fnl() ++
    (* "value" is dummy, must be changed *)
      prlist_strict identity (List.mapi (fun j t -> pp_instance_var (pp_type table pl t) (cnames.(i) ++ str (string_of_int j))) typs) 
        ++ fnl() ++
        hv 2 (pp_java_constructor cnames.(i) (List.mapi (fun j t -> (pp_type table pl t, cnames.(i) ++ str (string_of_int j))) typs)) ++ fnl() ++
    str "}") ++ fnl2() 
  in 
  pp_parameters pl ++ name ++
  pp_equiv table pl name inst ip_equiv ++ str " {}" ++ fnl() 
  ++ v 0 (prvecti pp_constructor ctyps)

(* [Inductive] may be mutual recursive *)
let pp_ind table ind =
  let initkwd = str "public interface " in
  let names =
    Array.mapi (fun i p -> if p.ip_logical then mt () else
                  pp_global_name table Type p.ip_typename_ref)
      ind.ind_packets
  in
  let cnames =
    Array.mapi
      (fun i p -> if p.ip_logical then [||] else
         Array.mapi (fun j _ -> pp_global table Cons p.ip_consnames_ref.(j))
           p.ip_types)
      ind.ind_packets
  in
  let rec pp i =
    if i >= Array.length ind.ind_packets then mt ()
    else
      let ip = ind.ind_packets.(i).ip_typename_ref in
      let ip_equiv = ind.ind_equiv, i in
      let p = ind.ind_packets.(i) in
      if is_custom ip then pp (i+1)
      else if p.ip_logical then pp_comment (str "logical inductive") ++ fnl()
      else (* essential *)
        let inst = p.ip_typename_ref.inst in
        initkwd ++ 
        pp_one_ind table inst ip_equiv p.ip_vars names.(i) cnames.(i) p.ip_types ++
        pp (i+1)
  in
  pp 0

let pp_mind table i =
  match i.ind_kind with
    | Singleton -> (* Record or Class with one element *) pp_singleton table i.ind_packets.(0)
    | Coinductive -> paren (str "extraction of coinductive definition is not implemented")
    | Record fields -> (* Record or Class with two or more elements *) pp_record table fields (i.ind_equiv,0) i.ind_packets.(0)
    | Standard -> pp_ind table i


let pp_decl table = function
  | Dind i -> pp_mind table i
  | Dtype _ -> str "type" ++ fnl2() (* TODO *)
  | Dfix (rv, defs, ty) ->
    (* Declare fields first, then assign in an instance initializer block.
       This avoids the "self-reference in initializer" error that occurs when a
       recursive lambda field initializer refers to the field being initialized. *)
    let n = Array.length rv in
    let decl i =
      if is_inline_custom rv.(i) then mt ()
      else str "static " ++ pp_type table [] ty.(i) ++ spc() ++ pp_global table Term rv.(i) ++ str ";" ++ fnl()
    in
    let init i =
      if is_inline_custom rv.(i) then mt ()
      else pp_global table Term rv.(i) ++ str " = " ++
        (if is_custom rv.(i) then str (find_custom rv.(i))
         else pp_expr table (empty_env table ()) [] defs.(i)) ++ str ";" ++ fnl()
    in
    Array.fold_left (++) (mt ()) (Array.init n decl) ++
    str "static {" ++ fnl() ++
    Array.fold_left (++) (mt ()) (Array.init n init) ++
    str "}" ++ fnl2()
  | Dterm (r, a, t) ->
      if is_inline_custom r then mt ()
      else
        hov 2 (str "static " ++ pp_type table [] t ++ spc() ++ pp_global table Term r ++ str " = " ++
                        (if is_custom r then str (find_custom r)
                         else pp_expr table (empty_env table ()) [] a) ++ str ";")
        ++ fnl2 ()


(* TODO : almost all definitions below are from Scheme.ml *)
let rec pp_structure_elem table = function
  | (l,SEdecl d) -> pp_decl table d
  | (l,SEmodule m) -> pp_module_expr table m.ml_mod_expr
  | (l,SEmodtype m) -> mt ()
      (* for the moment we simply discard module type *)

and pp_module_expr table = function
  | MEstruct (mp,sel) -> prlist_strict (fun e -> pp_structure_elem table e) sel
  | MEfunctor _ -> mt ()
      (* for the moment we simply discard unapplied functors *)
  | MEident _ | MEapply _ -> assert false
      (* should be expanded in extract_env *)

let pp_struct table =
  let pp_sel (mp,sel) = State.with_visibility table mp [] begin fun table ->
    prlist_strict (fun e -> pp_structure_elem table e) sel
  end in
  fun structure ->
    str "class Main {" ++ fnl() ++ fnl() ++
    str "static <A, B> B let(A val, Function<A, B> cont) { return cont.apply(val); }" ++
    fnl() ++ fnl() ++
    str "static <A> A error(String msg) { throw new RuntimeException(msg); }" ++
    fnl() ++ fnl() ++
    (* The dummy value replacing erased logical content ([MLdummy]). It is
       passed around and may even be applied at runtime, so it must be a
       benign value, never a throwing expression: self-application returns
       the value itself (same trick as the OCaml backend's [__]). *)
    str "static final Function<Object, Object> __dummy = new Function<Object, Object>() {" ++
    fnl() ++
    str "  public Object apply(Object x) { return this; }" ++
    fnl() ++
    str "};" ++
    fnl() ++ fnl() ++
    str "@SuppressWarnings(\"unchecked\")" ++
    fnl() ++
    str "static <A> A __() { return (A) __dummy; }" ++
    fnl() ++ fnl() ++
    prlist_strict pp_sel structure ++
    str "}" ++ fnl()
  
let file_naming state mp = file_of_modfile (State.get_table state) mp

let java_descr = {
  keywords = keywords;
  file_suffix = ".java";
  file_naming = file_naming;
  preamble = preamble;
  pp_struct = pp_struct;
  sig_suffix = None;
  sig_preamble = (fun _ _ _ _ _ -> mt ());
  pp_sig = (fun _ _ -> mt ());
  pp_decl = pp_decl;
}