(************************************************************************)
(*         ymoymoon         *)
(************************************************************************)

(*s Production of Java syntax. *)

open Pp
(* open CErrors *)
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

let paren = pp_par true

let pr_id id =
  str @@ String.map (fun c -> if c == '\'' then '$' else c) (Id.to_string id)

let pp_abst st = function
  | [] -> assert false
  | [id] -> paren (str "lambda " ++ paren (pr_id id) ++ spc () ++ st)
  | l -> paren (* TODO *)
        (str "lambdas " ++ paren (prlist_with_sep spc pr_id l) ++ spc () ++ st)

let pp_letin pat def body =
  let fstline = pat ++ str " =" ++ spc () ++ def ++ str ";" in
  hv 0 (hv 0 (hov 2 fstline ++ spc () ++ fnl ()) ++ spc () ++ hov 0 body)


let rec pp_expr table env args =
  let apply st = pp_apply st true args in
  function
    | MLrel n ->
        let id = get_db_name n env in apply (Id.print id)
    | MLapp (f,args') ->
        let stl = List.map (pp_expr table env []) args' in
        pp_expr table env (stl @ args) f
    | MLlam _ as a ->
        let fl,a' = collect_lams a in
        let fl,env' = push_vars (List.map id_of_mlid fl) env in
        apply (pp_abst (pp_expr table env' [] a') (List.rev fl))
    | MLletin (id,a1,a2) ->
        let i,env' = push_vars [id_of_mlid id] env in
        let pp_id = Id.print (List.hd i)
        and pp_a1 = pp_expr table env [] a1
        and pp_a2 = pp_expr table env' [] a2 in
        hv 0 (apply (pp_letin pp_id pp_a1 pp_a2))
    | _ -> str "__"

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