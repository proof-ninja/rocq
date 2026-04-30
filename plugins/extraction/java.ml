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
    [ "class"; "_"; "__"]
    Id.Set.empty

let pp_comment s = str "// " ++ s ++ fnl ()
let pp_header_comment = function
  | None -> mt ()
  | Some com -> pp_comment com ++ fnl () ++ fnl ()

let preamble _ _ comment _ _ =
  pp_header_comment comment 
  (* ++ import *)
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

let rec pp_abst st = function
  | [] -> assert false
  | [id] -> paren (pr_id id ++ str " -> " ++ spc () ++ st)
  | h::t -> paren (pr_id h ++ str " -> " ++ spc () ++ pp_abst st t)

let pp_letin pat def body =
  let fstline = pat ++ str " =" ++ spc () ++ def ++ str ";" in
  hv 0 (hv 0 (hov 2 fstline ++ spc () ++ fnl ()) ++ spc () ++ hov 0 body)
  

let rec pp_expr table env args =
  let apply st = pp_apply3 st true args in
  function
    | MLrel n ->
        let id = get_db_name n env in apply (Id.print id)
    | MLapp (f,args') ->
        let stl = List.map (pp_expr table env []) args' in
        pp_expr table env (stl @ args) f
    | MLlam _ as a ->
        let fl,a' = collect_lams a in (* [fl] : arguments, [a'] : body *)
        let fl,env' = push_vars (List.map id_of_mlid fl) env in
        apply (pp_abst (pp_expr table env' [] a') (List.rev fl))
    | MLletin (id,a1,a2) ->
        let i,env' = push_vars [id_of_mlid id] env in
        let pp_id = Id.print (List.hd i)
        and pp_a1 = pp_expr table env [] a1
        and pp_a2 = pp_expr table env' [] a2 in
        hv 0 (apply (pp_letin pp_id pp_a1 pp_a2))
    | MLglob r ->
        apply (pp_global table Term r)
    | MLcons (_,r,args') -> (* [r] : a name of a constructor *)
        assert (List.is_empty args);
        (* let st = *)
          paren (pp_global table Cons r ++
                 paren (prlist_with_sep comma (pp_expr table env []) args'))
        (* in
        if is_coinductive (State.get_table table) r then paren (str "delay " ++ st) else st *)
    | MLtuple _ -> user_err Pp.(str "Cannot handle tuples in Java yet.")
    | MLcase (_,_,pv) when not (is_regular_match pv) ->
        user_err Pp.(str "Cannot handle general patterns in Scheme yet.")
    | MLcase (_,t,pv) when is_custom_match pv -> (* TODO *)
        let mkfun (ids,_,e) =
          if not (List.is_empty ids) then named_lams (List.rev ids) e
          else dummy_lams (ast_lift 1 e) 1
        in
        apply
          (paren
             (hov 2
                (str (find_custom_match pv) ++ fnl () ++
                 prvect (fun tr -> pp_expr table env [] (mkfun tr) ++ fnl ()) pv
                 ++ pp_expr table env [] t)))
    | MLcase (typ,t, pv) -> (* TODO *)
        let e =
          if not (is_coinductive_type (State.get_table table) typ) then pp_expr table env [] t
          else paren (str "force" ++ spc () ++ pp_expr table env [] t)
        in
        apply (v 3 (paren (str "switch ... case ... " ++ e ++ fnl () ++ pp_pat table env pv)))
    | MLfix (i,ids,defs) -> (* TODO *)
        let ids',env' = push_vars (List.rev (Array.to_list ids)) env in
        pp_fix table env' i (Array.of_list (List.rev ids'),defs) args
    | MLexn s ->
        (* An [MLexn] may be applied, but I don't really care. *)
        paren (str "error" ++ spc () ++ qs s)
    | MLdummy _ ->
        str "__" (* An [MLdummy] may be applied, but I don't really care. *)
    | MLmagic a ->
        pp_expr table env args a
    | MLaxiom s -> paren (str "error \"AXIOM TO BE REALIZED (" ++ str s ++ str ")\"")
    | MLuint _ ->
      paren (str "Prelude.error \"EXTRACTION OF UINT NOT IMPLEMENTED\"")
    | MLfloat _ ->
      paren (str "Prelude.error \"EXTRACTION OF FLOAT NOT IMPLEMENTED\"")
    | MLstring _ ->
      paren (str "Prelude.error \"EXTRACTION OF STRING NOT IMPLEMENTED\"")
    | MLparray _ ->
            paren (str "Prelude.error \"EXTRACTION OF PARRAY NOT IMPLEMENTED\"")

  (* TODO : from Scheme.ml etc. *)
and pp_one_pat table env (ids,p,t) =
  let r = match p with
    | Pusual r -> r
    | Pcons (r,l) -> r (* cf. the check [is_regular_match] above *)
    | _ -> assert false
  in
  let ids,env' = push_vars (List.rev_map id_of_mlid ids) env in
  let args =
    if List.is_empty ids then mt ()
    else (str " " ++ prlist_with_sep spc pr_id (List.rev ids))
  in
  (pp_global table Cons r ++ args), (pp_expr table env' [] t)

and pp_pat table env pv =
  prvect_with_sep fnl
    (fun x -> let s1,s2 = pp_one_pat table env x in
     hov 2 (str "((" ++ s1 ++ str ")" ++ spc () ++ s2 ++ str ")")) pv

and pp_fix table env i (ids,bl) args =
  paren
    (v 0 (str "let rec " ++
          prvect_with_sep
            (fun () -> fnl () ++ str "and ")
            (fun (fi,ti) -> Id.print fi (* ++ pp_function table env ti *))
            (Array.map2 (fun id b -> (id,b)) ids bl) ++
          fnl () ++
          hov 2 (str "in " ++ pp_apply (Id.print ids.(i)) false args)))
     
(* TODO : almost all definitions below are from Scheme.ml *)
let pp_global table k r =
  if is_inline_custom r then str (find_custom r)
  else str (Common.pp_global table k r)

let pp_decl table = function
  | Dind _ -> mt ()
  | Dtype _ -> mt ()
  | Dfix (rv, defs,_) ->
      let names = Array.map
        (fun r -> if is_inline_custom r then mt () else pp_global table Term r) rv
      in
      prvecti
        (fun i r ->
          let void = is_inline_custom r ||
            (not (is_custom r) &&
             match defs.(i) with MLexn "UNUSED" -> true | _ -> false)
          in
          if void then mt ()
          else
            hov 2
              (names.(i) ++ spc () ++
                        (if is_custom r then str (find_custom r)
                         else pp_expr table (empty_env table ()) [] defs.(i))
               ++ fnl ()) ++ fnl ())
        rv
  | Dterm (r, a, _) ->
      if is_inline_custom r then mt ()
      else
        hov 2 (pp_global table Term r ++ spc () ++
                        (if is_custom r then str (find_custom r)
                         else pp_expr table (empty_env table ()) [] a))
        ++ fnl2 ()

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