(************************************************************************)
(*         *      The Rocq Prover / The Rocq Development Team           *)
(*  v      *         Copyright INRIA, CNRS and contributors             *)
(* <O___,, * (see version control and CREDITS file for authors & dates) *)
(*   \VV/  **************************************************************)
(*    //   *    This file is distributed under the terms of the         *)
(*         *     GNU Lesser General Public License Version 2.1          *)
(*         *     (see LICENSE file for the text of the license)         *)
(************************************************************************)

open Names
open ModPath
open CErrors
open Util
open Miniml
open Table
open Mlutil

(*S Functions upon ML modules. *)

(** Note: a syntax like [(F M) with ...] is actually legal, see for instance
    bug #4720. Hence the code below tries to handle [MTsig], maybe not in
    a perfect way, but that should be enough for the use of [se_iter] below. *)

let rec msid_of_mt = function
  | MTident mp -> mp
  | MTsig(mp,_) -> mp
  | MTwith(mt,_)-> msid_of_mt mt
  | MTfunsig _ -> assert false (* A functor cannot be inside a MTwith *)

(*s Apply some functions upon all [ml_decl] and [ml_spec] found in a
   [ml_structure]. *)

let se_iter do_decl do_spec do_mp =
  let rec mt_iter = function
    | MTident mp -> do_mp mp
    | MTfunsig (_,mt,mt') -> mt_iter mt; mt_iter mt'
    | MTwith (mt, ML_With_type (rlv, idl, l, t))->
        let mp_mt = msid_of_mt mt in
        let l',idl' = List.sep_last idl in
        let mp_w =
          List.fold_left (fun mp l -> MPdot(mp, l)) mp_mt idl'
        in
        let r = GlobRef.ConstRef (Constant.make2 mp_w l') in
        let r = { glob = r; inst = rlv } in
        mt_iter mt; do_spec (Stype(r,l,Some t))
    | MTwith (mt,ML_With_module(idl,mp))->
        let mp_mt = msid_of_mt mt in
        let mp_w =
          List.fold_left (fun mp l -> MPdot(mp, l)) mp_mt idl
        in
        mt_iter mt; do_mp mp_w; do_mp mp
    | MTsig (_, sign) -> List.iter spec_iter sign
  and spec_iter = function
    | (_,Spec s) -> do_spec s
    | (_,Smodule mt) -> mt_iter mt
    | (_,Smodtype mt) -> mt_iter mt
  in
  let rec se_iter = function
    | (_,SEdecl d) -> do_decl d
    | (_,SEmodule m) ->
        me_iter m.ml_mod_expr; mt_iter m.ml_mod_type
    | (_,SEmodtype m) -> mt_iter m
  and me_iter = function
    | MEident mp -> do_mp mp
    | MEfunctor (_,mt,me) -> me_iter me; mt_iter mt
    | MEapply (me,me') -> me_iter me; me_iter me'
    | MEstruct (msid, sel) -> List.iter se_iter sel
  in
  se_iter

let struct_iter do_decl do_spec do_mp s =
  List.iter
    (function (_,sel) -> List.iter (se_iter do_decl do_spec do_mp) sel) s

(*s Apply some fonctions upon all references in [ml_type], [ml_ast],
  [ml_decl], [ml_spec] and [ml_structure]. *)

type do_ref = global -> unit

let record_iter_references do_term = function
  | Record l -> List.iter (Option.iter do_term) l
  | _ -> ()

let type_iter_references do_type t =
  let rec iter = function
    | Tglob (r,l) -> do_type r; List.iter iter l
    | Tarr (a,b) -> iter a; iter b
    | _ -> ()
  in iter t

let patt_iter_references do_cons p =
  let rec iter = function
    | Pcons (r,l) -> do_cons r; List.iter iter l
    | Pusual r -> do_cons r
    | Ptuple l -> List.iter iter l
    | Prel _ | Pwild -> ()
  in iter p

let ast_iter_references do_term do_cons do_type a =
  let rec iter a =
    ast_iter iter a;
    match a with
      | MLglob r -> do_term r
      | MLcons (_,r,_) -> do_cons r
      | MLcase (ty,_,v) ->
        type_iter_references do_type ty;
        Array.iter (fun (_,p,_) -> patt_iter_references do_cons p) v

      | MLrel _ | MLlam _ | MLapp _ | MLletin _ | MLtuple _ | MLfix _ | MLexn _
      | MLdummy _ | MLaxiom _ | MLmagic _ | MLuint _ | MLfloat _
      | MLstring _ | MLparray _ -> ()
  in iter a

let ind_iter_references do_term do_cons do_type ind =
  let type_iter = type_iter_references do_type in
  let cons_iter cp l = do_cons cp; List.iter type_iter l in
  let packet_iter i p =
    let () = do_type p.ip_typename_ref in
    let () = if lang () == Ocaml then begin
        let inst = ind.ind_packets.(0).ip_typename_ref.inst in
        (match ind.ind_equiv with
         | Miniml.Equiv kne -> do_type { glob = (GlobRef.IndRef (MutInd.make1 kne, i)); inst };
         | _ -> ())
      end
    in
    Array.iteri (fun j -> cons_iter p.ip_consnames_ref.(j)) p.ip_types
  in
  let () = if lang () == Ocaml then record_iter_references do_term ind.ind_kind in
  Array.iteri (fun i p -> packet_iter i p) ind.ind_packets

let decl_iter_references do_term do_cons do_type =
  let type_iter = type_iter_references do_type
  and ast_iter = ast_iter_references do_term do_cons do_type in
  function
    | Dind ind -> ind_iter_references do_term do_cons do_type ind
    | Dtype (r,_,t) -> do_type r; type_iter t
    | Dterm (r,a,t) -> do_term r; ast_iter a; type_iter t
    | Dfix(rv,c,t) ->
        Array.iter do_term rv; Array.iter ast_iter c; Array.iter type_iter t

let spec_iter_references do_term do_cons do_type = function
  | Sind ind -> ind_iter_references do_term do_cons do_type ind
  | Stype (r,_,ot) -> do_type r; Option.iter (type_iter_references do_type) ot
  | Sval (r,t) -> do_term r; type_iter_references do_type t

(*s Searching occurrences of a particular term (no lifting done). *)

exception Found

let rec ast_search f a =
  if f a then raise Found else ast_iter (ast_search f) a

let decl_ast_search f = function
  | Dterm (_,a,_) -> ast_search f a
  | Dfix (_,c,_) -> Array.iter (ast_search f) c
  | _ -> ()

let struct_ast_search f s =
  try struct_iter (decl_ast_search f) (fun _ -> ()) (fun _ -> ()) s; false
  with Found -> true

let rec type_search f = function
  | Tarr (a,b) -> type_search f a; type_search f b
  | Tglob (r,l) -> List.iter (type_search f) l
  | u -> if f u then raise Found

let decl_type_search f = function
  | Dind {ind_packets = p}  ->
      Array.iter
        (fun {ip_types=v} -> Array.iter (List.iter (type_search f)) v) p
  | Dterm (_,_,u) -> type_search f u
  | Dfix (_,_,v) -> Array.iter (type_search f) v
  | Dtype (_,_,u) -> type_search f u

let spec_type_search f = function
  | Sind {ind_packets = p} ->
      Array.iter
        (fun {ip_types=v} -> Array.iter (List.iter (type_search f)) v) p
  | Stype (_,_,ot) -> Option.iter (type_search f) ot
  | Sval (_,u) -> type_search f u

let struct_type_search f s =
  try
    struct_iter (decl_type_search f) (spec_type_search f) (fun _ -> ()) s;
    false
  with Found -> true


(*s Generating the signature. *)

let rec msig_of_ms = function
  | [] -> []
  | (l,SEdecl (Dind i)) :: ms ->
      (l,Spec (Sind i)) :: (msig_of_ms ms)
  | (l,SEdecl (Dterm (r,_,t))) :: ms ->
      (l,Spec (Sval (r,t))) :: (msig_of_ms ms)
  | (l,SEdecl (Dtype (r,v,t))) :: ms ->
      (l,Spec (Stype (r,v,Some t))) :: (msig_of_ms ms)
  | (l,SEdecl (Dfix (rv,_,tv))) :: ms ->
      let msig = ref (msig_of_ms ms) in
      for i = Array.length rv - 1 downto 0 do
        msig := (l,Spec (Sval (rv.(i),tv.(i))))::!msig
      done;
      !msig
  | (l,SEmodule m) :: ms -> (l,Smodule m.ml_mod_type) :: (msig_of_ms ms)
  | (l,SEmodtype m) :: ms -> (l,Smodtype m) :: (msig_of_ms ms)

let signature_of_structure s =
  List.map (fun (mp,ms) -> mp,msig_of_ms ms) s

let rec mtyp_of_mexpr = function
  | MEfunctor (id,ty,e) -> MTfunsig (id,ty, mtyp_of_mexpr e)
  | MEstruct (mp,str) -> MTsig (mp, msig_of_ms str)
  | _ -> assert false


(*s Searching one [ml_decl] in a [ml_structure] by its [global_reference] *)

let is_modular = function
  | SEdecl _ -> false
  | SEmodule _ | SEmodtype _ -> true

let rec search_structure l m = function
  | [] -> raise Not_found
  | (lab,d)::_ when Id.equal lab l && (is_modular d : bool) == m -> d
  | _::fields -> search_structure l m fields

let get_decl_in_structure r struc =
  try
    let base_mp,ll = labels_of_ref r in
    if not (at_toplevel base_mp) then error_not_visible r;
    let sel = List.assoc_f ModPath.equal base_mp struc in
    let rec go ll sel = match ll with
      | [] -> assert false
      | l :: ll ->
          match search_structure l (not (List.is_empty ll)) sel with
            | SEdecl d -> d
            | SEmodtype m -> assert false
            | SEmodule m ->
                let rec aux = function
                  | MEstruct (_,sel) -> go ll sel
                  | MEfunctor (_,_,sel) -> aux sel
                  | MEident _ | MEapply _ -> error_not_visible r
                in aux m.ml_mod_expr

    in go ll sel
  with Not_found ->
    anomaly (Pp.str "reference not found in extracted structure.")


(*s Optimization of a [ml_structure]. *)

(* Some transformations of ML terms. [optimize_struct] simplify
   all beta redexes (when the argument does not occur, it is just
   thrown away; when it occurs exactly once it is substituted; otherwise
   a let-in redex is created for clarity) and iota redexes, plus some other
   optimizations. *)

let dfix_to_mlfix rv av i =
  let rec make_subst n s =
    if n < 0 then s
    else make_subst (n-1) (Refmap'.add rv.(n) (n+1) s)
  in
  let s = make_subst (Array.length rv - 1) Refmap'.empty
  in
  let rec subst n t = match t with
    | MLglob refe ->
        (try MLrel (n + (Refmap'.find refe s)) with Not_found -> t)
    | _ -> ast_map_lift subst n t
  in
  let ids = Array.map label_of_r rv in
  let c = Array.map (subst 0) av
  in MLfix(i, ids, c)

(* [optim_se] applies the [normalize] function everywhere and does the
   inlining of code. The inlined functions are kept for the moment in
   order to preserve the global interface, later [depcheck_se] will get
   rid of them if possible *)

let rec optim_se table top to_appear s = function
  | [] -> []
  | (l,SEdecl (Dterm (r,a,t))) :: lse ->
      let a = normalize (ast_glob_subst !s a) in
      let i = inline table r a in
      if i then s := Refmap'.add r a !s;
      let d = match dump_unused_vars (optimize_fix a) with
        | MLfix (0, _, [|c|]) ->
          Dfix ([|r|], [|ast_subst (MLglob r) c|], [|t|])
        | a -> Dterm (r, a, t)
      in
      (l,SEdecl d) :: (optim_se table top to_appear s lse)
  | (l,SEdecl (Dfix (rv,av,tv))) :: lse ->
      let av = Array.map (fun a -> normalize (ast_glob_subst !s a)) av in
      (* This fake body ensures that no fixpoint will be auto-inlined. *)
      let fake_body = MLfix (0,[||],[||]) in
      for i = 0 to Array.length rv - 1 do
        if inline table rv.(i) fake_body
        then s := Refmap'.add rv.(i) (dfix_to_mlfix rv av i) !s
      done;
      let av' = Array.map dump_unused_vars av in
      (l,SEdecl (Dfix (rv, av', tv))) :: (optim_se table top to_appear s lse)
  | (l,SEmodule m) :: lse ->
      let m = { m with ml_mod_expr = optim_me table to_appear s m.ml_mod_expr}
      in (l,SEmodule m) :: (optim_se table top to_appear s lse)
  | se :: lse -> se :: (optim_se table top to_appear s lse)

and optim_me table to_appear s = function
  | MEstruct (msid, lse) -> MEstruct (msid, optim_se table false to_appear s lse)
  | MEident mp as me -> me
  | MEapply (me, me') ->
      MEapply (optim_me table to_appear s me, optim_me table to_appear s me')
  | MEfunctor (mbid,mt,me) -> MEfunctor (mbid,mt, optim_me table to_appear s me)

(* After these optimisations, some dependencies may not be needed anymore.
   For non-library extraction, we recompute a minimal set of dependencies
   for first-level definitions (no module pruning yet). *)

let base_r r = let open GlobRef in match r.glob with
  | ConstRef _ -> r
  | IndRef (kn,_) -> { glob = IndRef (kn, 0); inst = r.inst }
  | ConstructRef ((kn,_),_) -> { glob = IndRef (kn, 0); inst = r.inst }
  | _ -> assert false

type needed = {
  needed_mp : ModPath.Set.t;
  needed_rf : Refset'.t;
}

let add_needed nd r =
  nd := { !nd with needed_rf = Refset'.add (base_r r) !nd.needed_rf }

let add_needed_mp nd mp =
  nd := { !nd with needed_mp = ModPath.Set.add mp !nd.needed_mp }

let found_needed nd r =
  nd := { !nd with needed_rf = Refset'.remove (base_r r) !nd.needed_rf }

let is_needed nd r =
  let r = base_r r in
  Refset'.mem r nd.needed_rf || ModPath.Set.mem (modpath_of_r r) nd.needed_mp

let declared_refs = function
  | Dind p -> [p.ind_packets.(0).ip_typename_ref]
  | Dtype (r,_,_) -> [r]
  | Dterm (r,_,_) -> [r]
  | Dfix (rv,_,_) -> Array.to_list rv

(* Computes the dependencies of a declaration, except in case
   of custom extraction. *)

let compute_deps_decl nd decl =
  let add_needed r = add_needed nd r in
  match decl with
  | Dind ind ->
      (* Todo Later : avoid dependencies when Extract Inductive *)
      ind_iter_references add_needed add_needed add_needed ind
  | Dtype (r,ids,t) ->
      if not (is_custom r) then type_iter_references add_needed t
  | Dterm (r,u,t) ->
      type_iter_references add_needed t;
      if not (is_custom r) then
        ast_iter_references add_needed add_needed add_needed u
  | Dfix _ as d ->
      decl_iter_references add_needed add_needed add_needed d

let compute_deps_spec nd spc =
  let add_needed r = add_needed nd r in
  match spc with
  | Sind ind ->
      (* Todo Later : avoid dependencies when Extract Inductive *)
      ind_iter_references add_needed add_needed add_needed ind
  | Stype (r,ids,t) ->
      if not (is_custom r) then Option.iter (type_iter_references add_needed) t
  | Sval (r,t) ->
      type_iter_references add_needed t

let rec depcheck_se table nd = function
  | [] -> []
  | ((l,SEdecl d) as t) :: se ->
    let se' = depcheck_se table nd se in
    let refs = declared_refs d in
    let refs' = List.filter (fun r -> is_needed !nd r) refs in
    if List.is_empty refs' then
      (List.iter (fun r -> remove_info_axiom table r) refs;
       List.iter (fun r -> remove_opaque table r) refs;
       se')
    else
      let () = List.iter (fun r -> found_needed nd r) refs' in
      (* Hack to avoid extracting unused part of a Dfix *)
      begin match d with
        | Dfix (rv,trms,tys) when (List.for_all is_custom refs') ->
          let trms' =  Array.make (Array.length rv) (MLexn "UNUSED") in
          ((l,SEdecl (Dfix (rv,trms',tys))) :: se')
        | _ ->
          let () = compute_deps_decl nd d in
          t :: se'
      end
  | t :: se ->
    let se' = depcheck_se table nd se in
    let iter_decl d = compute_deps_decl nd d in
    let iter_spec s = compute_deps_spec nd s in
    let iter_mp mp = add_needed_mp nd mp in
    let () = se_iter iter_decl iter_spec iter_mp t in
    t :: se'

let rec depcheck_struct table nd = function
  | [] -> []
  | (mp,lse)::struc ->
      let struc' = depcheck_struct table nd struc in
      let lse' = depcheck_se table nd lse in
      if List.is_empty lse' then struc' else (mp,lse')::struc'

exception RemainingImplicit of kill_reason

let check_for_remaining_implicits struc =
  let check = function
    | MLdummy (Kimplicit _ as k) -> raise (RemainingImplicit k)
    | _ -> false
  in
  try ignore (struct_ast_search check struc)
  with RemainingImplicit k -> err_or_warn_remaining_implicit k

(*s Canonical inductive references (Java). *)

(* A module alias ([Module M := Other]) or an [Include] gives an inductive
   a second user name whose canonical name is the original's. For every
   language but OCaml the extraction core expands such modules, so the
   alias arrives as a full copy of the inductive block, keyed by the alias
   name. Java has no type aliases and prints everything into one flat
   class, so the copy would become a distinct, incompatible type: a value
   built as [M.P] could not be passed where [Other.point] is expected
   although both are the same type in Rocq. Instead every inductive
   reference is redirected to the canonical block and the alias block's
   declaration is dropped. This must run before [depcheck_struct], which
   decides reachability by user name and would otherwise prune the
   canonical block ([Visit.add_ref] in extract_env.ml makes sure it was
   extracted in the first place). The objects requested on the command
   line ([to_appear], whose only consumer is dead-code removal) are
   redirected the same way, and every dropped alias block adds its
   canonical block to them: otherwise a request for an alias name, or for
   the alias module itself, would seed dead-code removal with names that
   no declaration carries any more, and the canonical block would be
   pruned unless something else happened to refer to it. Since an alias
   block was never prunable (dead-code removal keeps submodules whole),
   seeding every dropped block keeps exactly what was kept before, no
   less and no more. For an inductive that is not aliased both names
   agree and nothing changes. Constants are left alone: a duplicated
   constant is dead weight, not a type mismatch.

   Known gap: the custom-extraction table is keyed by user name, so an
   [Extract Inductive] given for an alias name is not seen through the
   canonical name and is silently ignored (TODO; [Extract Inductive] is
   not functional for Java yet anyway).

   All of this assumes that the whole extraction ends up in one Java
   class, which only holds for monolithic extraction ([Extraction "f"]
   and [Recursive Extraction]). In modular mode ([Separate Extraction],
   [Extraction Library]) the canonical block lives in another file, and
   Java has no way to refer to it (no imports, no qualification), so the
   redirection is not applied there. *)

let canonical_mind kn =
  let c = MutInd.canonical kn in
  if KerName.equal c (MutInd.user kn) then kn else MutInd.make1 c

let canonical_ref r = match r.glob with
  | GlobRef.IndRef (kn, i) ->
      { r with glob = GlobRef.IndRef (canonical_mind kn, i) }
  | GlobRef.ConstructRef ((kn, i), j) ->
      { r with glob = GlobRef.ConstructRef ((canonical_mind kn, i), j) }
  | GlobRef.ConstRef _ | GlobRef.VarRef _ -> r

let rec canonical_type = function
  | Tglob (r, args) -> Tglob (canonical_ref r, List.map canonical_type args)
  | Tarr (a, b) -> Tarr (canonical_type a, canonical_type b)
  | Tmeta { contents = Some u; _ } -> canonical_type u
  | Tvar _ | Tvar' _ | Tmeta _ | Tdummy _ | Tunknown | Taxiom as t -> t

let rec canonical_pat = function
  | Pcons (r, l) -> Pcons (canonical_ref r, List.map canonical_pat l)
  | Pusual r -> Pusual (canonical_ref r)
  | Ptuple l -> Ptuple (List.map canonical_pat l)
  | Prel _ | Pwild as p -> p

(* [MLcons] and [MLcase] are handled here because [ast_map] leaves their
   heads alone. *)
let rec canonical_ast = function
  | MLcons (ty, r, args) ->
      MLcons (canonical_type ty, canonical_ref r, List.map canonical_ast args)
  | MLcase (ty, e, br) ->
      MLcase (canonical_type ty, canonical_ast e,
              Array.map (fun (ids, p, b) -> (ids, canonical_pat p, canonical_ast b)) br)
  | a -> ast_map canonical_ast a

let is_alias_ind ind =
  Array.exists
    (fun p -> match p.ip_typename_ref.glob with
       | GlobRef.IndRef (kn, _) ->
           not (KerName.equal (MutInd.canonical kn) (MutInd.user kn))
       | _ -> false)
    ind.ind_packets

(* Field types of the surviving blocks may still mention an alias. *)
let canonical_ind ind =
  { ind with ind_packets =
      Array.map
        (fun p -> { p with ip_types = Array.map (List.map canonical_type) p.ip_types })
        ind.ind_packets }

(* [dropped] collects, for every alias block that is removed, the
   reference to the canonical block that takes its place. *)

let canonical_decl dropped = function
  | Dind ind ->
      if is_alias_ind ind then begin
        (* One entry per block: dead-code removal keys every packet of a
           block by its first one ([base_r]). *)
        dropped := canonical_ref ind.ind_packets.(0).ip_typename_ref :: !dropped;
        None
      end
      else Some (Dind (canonical_ind ind))
  | Dtype (r, vs, t) -> Some (Dtype (r, vs, canonical_type t))
  | Dterm (r, a, t) -> Some (Dterm (r, canonical_ast a, canonical_type t))
  | Dfix (rv, av, tv) ->
      Some (Dfix (rv, Array.map canonical_ast av, Array.map canonical_type tv))

let rec canonical_elems dropped sel =
  List.filter_map
    (fun (l, e) -> match e with
       | SEdecl d -> Option.map (fun d -> (l, SEdecl d)) (canonical_decl dropped d)
       | SEmodule m ->
           Some (l, SEmodule { m with ml_mod_expr = canonical_mexpr dropped m.ml_mod_expr })
       | SEmodtype _ -> Some (l, e))
    sel

and canonical_mexpr dropped = function
  | MEstruct (mp, sel) -> MEstruct (mp, canonical_elems dropped sel)
  | MEident _ | MEfunctor _ | MEapply _ as me -> me

(* Returns the rewritten structure together with the canonical references
   of the alias blocks that were dropped. Those must be added to the
   objects to appear: an alias block is in the structure only because its
   module was needed, and with the block gone, nothing else may keep the
   canonical block alive (e.g. a request for the alias module itself,
   whose path is not a reference that could be redirected). *)

let canonicalize_inductives struc =
  let dropped = ref [] in
  let struc = List.map (fun (mp, sel) -> (mp, canonical_elems dropped sel)) struc in
  struc, !dropped

let optimize_struct table to_appear struc =
  let struc, to_appear =
    if lang () == Java && not (Common.State.get_modular table) then
      let struc, dropped = canonicalize_inductives struc in
      struc, (List.map canonical_ref (fst to_appear) @ dropped, snd to_appear)
    else struc, to_appear
  in
  let subst = ref (Refmap'.empty : ml_ast Refmap'.t) in
  let opt_struc =
    List.map (fun (mp,lse) -> (mp, optim_se (Common.State.get_table table) true (fst to_appear) subst lse))
      struc
  in
  let mini_struc =
    if Common.State.get_library table then
      List.filter (fun (_,lse) -> not (List.is_empty lse)) opt_struc
    else
      let nd = ref { needed_mp = ModPath.Set.empty; needed_rf = Refset'.empty } in
      let () = List.iter (fun r -> add_needed nd r) (fst to_appear) in
      let () = List.iter (fun mp -> add_needed_mp nd mp) (snd to_appear) in
      depcheck_struct (Common.State.get_table table) nd opt_struc
  in
  let () = check_for_remaining_implicits mini_struc in
  mini_struc
