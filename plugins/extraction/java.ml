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
  | _ -> (prlist_with_sep (fun _ -> str " -> ") pr_id idlist) ++ str " -> { \n" 
    ++ spc () ++ str "return " ++ st ++ str "; \n }"

let pp_letin pat def body =
  let fstline = pat ++ str " =" ++ spc () ++ def ++ str ";" in
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
          paren (str "Constructor" ++ pp_global table Cons r ++
                 paren (prlist_with_sep comma (pp_expr table env) args'))
        (* in
        if is_coinductive (State.get_table table) r then paren (str "delay " ++ st) else st *)
    | MLtuple _ -> user_err Pp.(str "Cannot handle tuples in Java yet.")
    | MLcase (_,_,pv) when not (is_regular_match pv) ->
        user_err Pp.(str "Cannot handle general patterns in Scheme yet.")
    | MLcase (typ,t, pv) -> (* TODO *)
        str "switch ... case ... " 
    | MLfix (i,ids,defs) -> (* TODO *)
        str "fixpoint" 
    | MLexn s ->
        (* An [MLexn] may be applied, but I don't really care. *)
        paren (str "error" ++ spc () ++ qs s)
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


let pp_global table k r =
  if is_inline_custom r then str (find_custom r)
  else str (Common.pp_global table k r)

let pp_mind table i = (* TODO *)
  match i.ind_kind with
    | Singleton -> str "single"
    | Coinductive -> str "coind"
    | Record _ -> str "record"
    | Standard -> str "standard"
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