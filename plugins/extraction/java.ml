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
    "const"; "float"; "native"; "super"; "while"; "_" ]
    Id.Set.empty

let pp_comment s = str "// " ++ s ++ fnl ()
let pp_header_comment = function
  | None -> mt ()
  | Some com -> pp_comment com ++ fnl () ++ fnl ()

let preamble _ _ comment _ _ =
  pp_header_comment comment 
  (* ++ import java.util.function.Function; *)
  (* ++ dummy *)
  ++ str "public class Main "
  (* ++ str "public static void main (String[] args) " *)

let comma = fun _ -> str ", "
let paren = pp_par true

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
    | Tdummy _ -> str "__"
    | Tunknown -> str "__"
  in
  hov 0 (pp_rec t)

let pp_apply st args = 
  let rec pp_rec args = match args with
    | [] -> str ""
    | h::t  -> str ".apply" ++ paren h ++ pp_rec t 
  in
  st ++ pp_rec args

let pp_abst st idlist = match idlist with
  | [] -> assert false
  | _ -> (prlist_with_sep (fun _ -> str " -> ") pr_id idlist) ++ str " -> { " 
    ++ spc () ++ str "return " ++ st ++ str "; \n }"

let pp_letin pat def body =
  let fstline = pat ++ str " = " ++ def ++ str ";" in
  hv 0 (hv 0 (hov 2 fstline ++ spc () ++ fnl ()) ++ spc () ++ hov 0 body)
  

let rec pp_expr table env =
  function
    | MLrel n ->
        let id = get_db_name n env in (Id.print id)
    | MLapp (f,args') ->
        let stl = List.map (pp_expr table env) args' in
        let func = pp_expr table env f in
        pp_apply func stl
    | MLlam _ as a ->
        let fl,a' = collect_lams a in (* [fl] : arguments, [a'] : body *)
        let fl,env' = push_vars (List.map id_of_mlid fl) env in
        (pp_abst (pp_expr table env' a') (List.rev fl))
    | MLletin (id,a1,a2) ->
        let i,env' = push_vars [id_of_mlid id] env in
        let pp_id = Id.print (List.hd i)
        and pp_a1 = pp_expr table env a1
        and pp_a2 = pp_expr table env' a2 in
        hv 0 (pp_letin pp_id pp_a1 pp_a2)
    | MLglob r ->
        (pp_global table Term r)
    | MLcons (_,r,args') -> (* [r] : a name of a constructor *)
        (* let st = *)
          pp_global table Cons r ++ paren (prlist_with_sep comma (pp_expr table env) args')
        (* in
        if is_coinductive (State.get_table table) r then paren (str "delay " ++ st) else st *)
    | MLtuple _ -> user_err Pp.(str "Cannot handle tuples in Java yet.")
    | MLcase (_,_,pv) when not (is_regular_match pv) ->
        user_err Pp.(str "Cannot handle general patterns in Java yet.")
    | MLcase (typ,t, pv) -> (* TODO *)
        str "switch ... case ... " 
    | MLfix (i,ids,defs) -> (* TODO *)
        str "fixpoint" 
    | MLexn s ->
        (* An [MLexn] may be applied, but I don't really care. *)
        paren (str "error " ++ qs s)
    | MLdummy _ ->
        str "__" (* An [MLdummy] may be applied, but I don't really care. *)
    | MLmagic a ->
        pp_expr table env a
    | MLaxiom s -> paren (str "error \"AXIOM TO BE REALIZED (" ++ str s ++ str ")\"")
    | MLuint _ ->
      paren (str "Prelude.error \"EXTRACTION OF UINT NOT IMPLEMENTED\"")
    | MLfloat _ ->
      paren (str "Prelude.error \"EXTRACTION OF FLOAT NOT IMPLEMENTED\"")
    | MLstring _ ->
      paren (str "Prelude.error \"EXTRACTION OF STRING NOT IMPLEMENTED\"")
    | MLparray _ ->
            paren (str "Prelude.error \"EXTRACTION OF PARRAY NOT IMPLEMENTED\"")

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

(* class with one constructor *)
let pp_singleton table packet =
  let name = pp_global_name table Type packet.ip_typename_ref in
  let l = rename_tvars keywords packet.ip_vars in
  str "record " ++ pp_parameters l ++ name ++ str " " ++
        paren (pp_type table l (List.hd packet.ip_types.(0)) ++ str " " ++ Id.print packet.ip_consnames.(0))
        ++ str " {} "

(* class with two or more constructors *)
let pp_record table fields ip_equiv packet =
  let ind = packet.ip_typename_ref in
  let name = pp_global_name table Type ind in
  let fieldnames = pp_fields table ind fields in
  let l = List.combine fieldnames packet.ip_types.(0) in
  let pl = rename_tvars keywords packet.ip_vars in
  str "record " ++ pp_parameters pl ++ name ++
  paren (prlist_with_sep (fun () -> str ", ")
           (fun (p,t) -> pp_type table pl t ++ str " " ++ p) l) ++
  pp_equiv table pl name ind.inst ip_equiv ++ str " {} "

(* one [Inductive a := ... .] *)
let pp_one_ind table inst ip_equiv pl name cnames ctyps =
  let pl = rename_tvars keywords pl in
  let pp_constructor i typs =
    fnl () ++
    str "record " ++ cnames.(i) 
    ++ paren (prlist_with_sep (fun () -> str ", ") (fun ty -> pp_type table pl ty ++ str " value") typs)
    ++ str " implements " ++ name ++ str " {} "
  in 
  pp_parameters pl ++ name ++
  pp_equiv table pl name inst ip_equiv ++ str " permits " 
  ++ prvect_with_sep (fun () -> str ", ") identity cnames ++ str " {}" ++ fnl() 
  ++ v 0 (prvecti pp_constructor ctyps)

(* [Inductive] may be mutual recursive *)
let pp_ind table ind =
  let initkwd = str "sealed interface " in
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

let pp_mind table i = (* TODO *)
  match i.ind_kind with
    | Singleton -> (* Record or Class with one element *) pp_singleton table i.ind_packets.(0)
    | Coinductive -> paren (str "extraction of coinductive definition is not implemented")
    | Record fields -> (* Record or Class with two or more elements *) pp_record table fields (i.ind_equiv,0) i.ind_packets.(0)
    | Standard -> pp_ind table i
    (* 
    OCaml : 
    type expr =
  | Int of int
  | Add of expr * expr
  
    Java :
  sealed interface Expr
    permits IntExpr, AddExpr {}
  record IntExpr(int value)
      implements Expr {}
  record AddExpr(Expr l, Expr r)
      implements Expr {} *)

let rec pp_decl table = function
  | Dind i -> pp_mind table i
  | Dtype _ -> str "type" (* TODO *)
  | Dfix (rv, defs,ty) -> 
    let terms = (Array.map3 (fun x y z -> Dterm (x, y, z)) rv defs ty) in 
    Array.fold_left (fun s term -> s ++ pp_decl table term ++ str "\n") (str "") terms
  | Dterm (r, a, t) ->
      if is_inline_custom r then mt ()
      else
        hov 2 (pp_type table [] t ++ spc() ++ pp_global table Term r ++ str " = " ++
                        (if is_custom r then str (find_custom r)
                         else pp_expr table (empty_env table ()) a))
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
  prlist_strict pp_sel
  
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