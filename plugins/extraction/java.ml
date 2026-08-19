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
    (* not keywords, but JLS 3.8 excludes BooleanLiteral and NullLiteral
       from Identifier as well *)
    "true"; "false"; "null";
    (* not Java keywords, but names of the generated wrapper class's helpers:
       reserve them so extracted identifiers get renamed instead of clashing *)
    "let"; "error"; "__"; "__dummy" ]
    Id.Set.empty

let is_java_ident_start c =
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c = '_' || c = '$'

let is_java_ident_part c = is_java_ident_start c || (c >= '0' && c <= '9')

(* JLS 3.8 defines a class name as a TypeIdentifier: an Identifier that is not
   one of these five contextual keywords. They are deliberately kept out of
   [keywords], which governs all extracted identifiers: they are perfectly
   legal as variable or method names, and only forbidden as type names. *)
let restricted_type_identifiers =
  List.fold_right (fun s -> Id.Set.add (Id.of_string s))
    [ "permits"; "record"; "sealed"; "var"; "yield" ]
    Id.Set.empty

let java_class_name id =
  let s = Id.to_string id in
  let valid =
    not (String.is_empty s)
    && is_java_ident_start s.[0]
    && String.for_all is_java_ident_part s
    && not (Id.Set.mem id keywords)
    && not (Id.Set.mem id restricted_type_identifiers)
  in
  if not valid then
    user_err Pp.(str "Extraction: " ++ Id.print id ++
                 str " cannot be used as a Java class name; \
                      choose a different output file name.");
  s

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

let pp_type table t =
  let rec pp_rec = function
    | Tmeta _ | Tvar' _ | Taxiom -> assert false
    (* Type variables are uniformly erased to [Object]: an ML type variable
       is parametric, so its runtime representative can be any reference
       type, and [Object] is the weakest valid Java type. Casts back to
       concrete types are inserted at use sites by the printer. *)
    | Tvar _ -> str "Object"
    | Tglob (r,[]) -> pp_global table Type r
    | Tglob (gr,l)
        when not (keep_singleton ()) && Rocqlib.check_ref sig_type_name gr.glob ->
        pp_tuple pp_rec l
    (* Erasure makes every generated class non-generic, so a type
       application prints as the bare class name. *)
    | Tglob (r,_) -> pp_global table Type r
    | Tarr (t1,t2) ->
        str "Function<" ++ pp_rec t1 ++ str ", " ++ pp_rec t2++ str ">"
    (* Both stand for "no informative type here". *)
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

let kn_of_ind r = let open GlobRef in match r.glob with
  | IndRef (kn,_) -> MutInd.user kn
  | _ -> assert false

let get_ind r = let open GlobRef in match r.glob with
  | IndRef _ -> r
  | ConstructRef (ind,_) -> { glob = IndRef ind; inst = r.inst }
  | _ -> assert false

let pp_gen_pat table = function
  | Pusual r -> pp_global_name table Cons r
  | Pcons _ -> user_err Pp.(str "Cannot handle deep patterns in Java yet.")
  | Ptuple _ -> user_err Pp.(str "Cannot handle tuple patterns in Java yet.")
  | Pwild | Prel _ -> assert false (* catch-all: handled in pp_pat_branches *)

let fix_arities = ref Int.Set.empty

let reset_fix_arities () =
  fix_arities := Int.Set.empty

let record_fix_arity k =
  fix_arities := Int.Set.add k !fix_arities

let rec is_fix_head = function
  | MLfix _ -> true
  | MLapp (f, _) -> is_fix_head f
  | MLmagic a -> is_fix_head a
  | _ -> false

let pp_fix_helper k =
  let tyvar i = str "A" ++ int i in
  let arg i = str "a" ++ int i in
  let xarg i = str "x" ++ int i in
  let rec fn_type i =
    if Int.equal i (k + 1) then str "R"
    else str "Function<" ++ tyvar i ++ str ", " ++ fn_type (i+1) ++ str ">"
  in
  let type_params =
    if Int.equal k 0 then str "<A1, R>"
    else str "<" ++ prlist_with_sep comma tyvar (List.init k (fun i -> i+1)) ++ str ", R>"
  in
  let apply_args prefix =
    prlist_strict (fun i -> str ".apply" ++ paren (prefix i)) (List.init k (fun i -> i+1))
  in
  if Int.equal k 0 then
    str "static <A1, R> Function<A1, R> fix0(Function<Function<A1, R>, Function<A1, R>> gen) {" ++ fnl() ++
    str "  return a1 -> fix1(gen, a1);" ++ fnl() ++
    str "}" ++ fnl2()
  else
    str "static " ++ type_params ++ spc() ++ str "R fix" ++ int k ++
    paren
      (str "Function<" ++ fn_type 1 ++ str ", " ++ fn_type 1 ++ str "> gen, " ++
       prlist_with_sep comma (fun i -> tyvar i ++ spc() ++ arg i) (List.init k (fun i -> i+1))) ++
    str " {" ++ fnl() ++
    str "  return gen.apply(" ++
    prlist_with_sep (fun () -> str " -> ") xarg (List.init k (fun i -> i+1)) ++
    str " -> fix" ++ int k ++ paren (str "gen, " ++ prlist_with_sep comma xarg (List.init k (fun i -> i+1))) ++
    str ")" ++ apply_args arg ++ str ";" ++ fnl() ++
    str "}" ++ fnl2()

(*s Printer-local type information for cast insertion.

    Erasure prints every [Tvar] as [Object], so a polymorphic result used at
    a concrete type needs a cast back ([(nat) ...]). We recover the types by
    a local propagation: declared types flow top-down (the [expected]
    argument of [pp_expr]), recoverable types flow bottom-up
    ([type_of_expr]), and a cast is emitted only where the erased forms
    disagree. This is checking, not inference: whenever information runs
    out we return [None] ("unknown"), which at worst omits a cast — javac
    then rejects the output instead of us emitting wrong code. On
    monomorphic code both sides always agree and the output is unchanged.

    Both maps are reset per [pp_struct] (same discipline as [fix_arities])
    and are filled as declarations are printed; declarations come in
    dependency order, so a use site always finds the types of the constants
    and inductives it refers to. *)

let const_types = ref Cmap_env.empty
let ind_sigs = ref Mindmap_env.empty
let type_aliases = ref Cmap_env.empty

let reset_type_info () =
  const_types := Cmap_env.empty;
  ind_sigs := Mindmap_env.empty;
  type_aliases := Cmap_env.empty

let record_const_type r ty = match r.glob with
  | GlobRef.ConstRef c -> const_types := Cmap_env.add c ty !const_types
  | _ -> ()

let lookup_const_type r = match r.glob with
  | GlobRef.ConstRef c -> Cmap_env.find_opt c !const_types
  | _ -> None

(*s Type synonyms ([Dtype]). Java has no type-alias feature, and wrapping
    the body in a class would change the runtime representation, so alias
    declarations are erased and every reference is expanded to the body.
    Bodies are recorded as [pp_decl] meets the declarations; declarations
    come in dependency order, so a reference always finds its alias. *)

let record_type_alias r body = match r.glob with
  | GlobRef.ConstRef c -> type_aliases := Cmap_env.add c body !type_aliases
  | _ -> ()

let lookup_type_alias r = match r.glob with
  | GlobRef.ConstRef c -> Cmap_env.find_opt c !type_aliases
  | _ -> None

(* Replaces every alias reference by its recorded body. The recursion
   terminates because a [Definition] cannot be recursive: an alias body only
   mentions aliases declared strictly earlier. Deliberately independent of
   [Mlutil.type_expand], which [Unset Extraction TypeExpand] turns into the
   identity; in Java the expansion is a correctness requirement, not a
   readability optimization, so it must not be switched off. *)
let rec expand_aliases t = match t with
  | Tglob (r, args) ->
      (match lookup_type_alias r with
       | Some body -> expand_aliases (type_subst_list args body)
       | None -> Tglob (r, List.map expand_aliases args))
  | Tarr (a, b) -> Tarr (expand_aliases a, expand_aliases b)
  | Tmeta { contents = Some u; _ } -> expand_aliases u
  | Tvar _ | Tvar' _ | Tdummy _ | Tunknown | Tmeta _ | Taxiom -> t

(* Constructor field types may mention aliases declared earlier. *)
let expand_ind_aliases ind =
  { ind with ind_packets =
      Array.map
        (fun p ->
           { p with ip_types = Array.map (List.map expand_aliases) p.ip_types })
        ind.ind_packets }

(* All packets of a block share the same [MutInd.t], so this records a
   single binding, harmlessly re-added once per packet; iterating just
   avoids assuming the array is non-empty or where an [IndRef] sits. *)
let record_ind ind =
  Array.iter
    (fun p -> match p.ip_typename_ref.glob with
       | GlobRef.IndRef (kn, _) -> ind_sigs := Mindmap_env.add kn ind !ind_sigs
       | _ -> ())
    ind.ind_packets

(* Argument types of constructor [r], still over the inductive's own type
   variables; instantiate them with [type_subst_list] and the type
   arguments of the scrutinee/constructor annotation. *)
let constructor_arg_types r = match r.glob with
  | GlobRef.ConstructRef ((kn, i), j) ->
      (match Mindmap_env.find_opt kn !ind_sigs with
       | Some ind when i < Array.length ind.ind_packets ->
           let p = ind.ind_packets.(i) in
           if 1 <= j && j <= Array.length p.ip_types then Some p.ip_types.(j - 1)
           else None
       | _ -> None)
  | _ -> None

(* The erased view of a type: the shape [pp_type] prints. Two types with
   equal erasures print to the same Java type, so no cast is needed between
   them. [Tunknown] is the erased form of [Object]. *)
let rec erase_type = function
  | Tarr (a, b) -> Tarr (erase_type a, erase_type b)
  | Tglob (gr, l) when not (keep_singleton ()) && Rocqlib.check_ref sig_type_name gr.glob ->
      (match l with [t] -> erase_type t | _ -> Tunknown)
  | Tglob (r, _) -> Tglob (r, [])
  | Tmeta { contents = Some t; _ } -> erase_type t
  | Tvar _ | Tvar' _ | Tdummy _ | Tunknown | Tmeta _ | Taxiom -> Tunknown

let rec erased_type_eq t1 t2 = match t1, t2 with
  | Tarr (a1, b1), Tarr (a2, b2) -> erased_type_eq a1 a2 && erased_type_eq b1 b2
  | Tglob (r1, _), Tglob (r2, _) -> GlobRef.CanOrd.equal r1.glob r2.glob
  | Tunknown, Tunknown -> true
  | _ -> false

let erases_to_object t = match erase_type t with Tunknown -> true | _ -> false

let rec strip_arrows t k =
  if Int.equal k 0 then Some t
  else match t with
    | Tarr (_, b) -> strip_arrows b (k - 1)
    | Tmeta { contents = Some t; _ } -> strip_arrows t k
    | _ -> None

(* Number of leading arrows in [t], capped at [k]. This matches the number
   of [Function] layers [pp_type] prints, hence the number of [.apply]
   calls that typecheck on a value of type [t] without a cast. *)
let rec arrows_upto t k =
  if Int.equal k 0 then 0
  else match t with
    | Tarr (_, b) -> 1 + arrows_upto b (k - 1)
    | Tmeta { contents = Some t; _ } -> arrows_upto t k
    | _ -> 0

(* Expected types of the first [k] arguments of a function of type [t];
   [None] entries where the arrow chain runs out. *)
let rec arg_types t k =
  if Int.equal k 0 then []
  else match t with
    | Tarr (a, b) -> Some a :: arg_types b (k - 1)
    | Tmeta { contents = Some t; _ } -> arg_types t k
    | _ -> List.init k (fun _ -> None)

(* Peels [k] lambda-argument types off [t]; returns them outermost first,
   together with the type of the body. *)
let rec peel_lams t k =
  if Int.equal k 0 then [], Some t
  else match t with
    | Tarr (a, b) -> let ps, r = peel_lams b (k - 1) in Some a :: ps, r
    | Tmeta { contents = Some t; _ } -> peel_lams t k
    | _ -> List.init k (fun _ -> None), None

(* Bottom-up type of an expression, where recoverable. [tenv] parallels the
   de Bruijn context of [env]: its head is the type of [MLrel 1]. *)
let rec type_of_expr tenv = function
  | MLrel n -> (try List.nth tenv (n - 1) with Failure _ | Invalid_argument _ -> None)
  | MLglob r -> lookup_const_type r
  | MLcons (typ, _, _) -> Some typ
  | MLapp (f, args) ->
      (match type_of_expr tenv f with
       | Some ft -> strip_arrows ft (List.length args)
       | None -> None)
  | MLletin (_, a1, a2) -> type_of_expr (type_of_expr tenv a1 :: tenv) a2
  | MLmagic _ (* exists precisely because the ML types disagree *)
  | MLlam _ | MLcase _ | MLfix _ | MLexn _ | MLdummy _ | MLaxiom _
  | MLtuple _ | MLuint _ | MLfloat _ | MLstring _ | MLparray _ -> None

(* Wraps [pp] in a cast to [expected] when both types are known and their
   erased Java forms differ. An unknown side inserts no cast: guessing
   would sprinkle casts over monomorphic code (whose output must not
   change), and a missing cast at worst fails javac. When the actual type
   is known and is not [Object], the cast goes through [(Object)] first:
   a direct cast between two distinct parameterized types (e.g. two
   [Function] shapes) would be rejected as inconvertible. *)
let pp_cast table ~expected ~actual pp =
  match expected, actual with
  | None, _ | _, None -> pp
  | Some ety, Some aty ->
      let ety = erase_type ety in
      match ety with
      | Tunknown -> pp
      | _ ->
          if erased_type_eq (erase_type aty) ety then pp
          else
            let bridge =
              if erases_to_object aty then mt () else str "(Object) "
            in
            paren (paren (pp_type table ety) ++ str " " ++ bridge ++ pp)

let rec pp_expr table env tenv expected args =
  let apply st = pp_app st args in
  let apply_cast head_ty st =
    let n = List.length args in
    match head_ty with
    | None -> pp_app st args
    | Some t ->
        let avail = arrows_upto t n in
        if Int.equal avail n then
          pp_cast table ~expected ~actual:(strip_arrows t n) (pp_app st args)
        else
          (* The head's type runs out of arrows before the arguments do: it
             returns a type variable that is instantiated to a function.
             Erasure makes the receiver's static Java type [Object] there,
             so each remaining [.apply] must first cast it back to
             [Function<Object, Object>]. An outer cast alone cannot help:
             javac rejects the intermediate [.apply] before it. *)
          let head_args, rest_args = List.chop avail args in
          let runout_ty = match strip_arrows t avail with
            | Some ty -> ty
            | None -> assert false
          in
          let fn_object = pp_type table (Tarr (Tunknown, Tunknown)) in
          let recv, _ =
            List.fold_left
              (fun (recv, first) arg ->
                 let bridge =
                   if first && not (erases_to_object runout_ty)
                   then str "(Object) " else mt ()
                 in
                 let recv =
                   paren (paren fn_object ++ str " " ++ bridge ++ recv)
                 in
                 pp_app recv [arg], false)
              (pp_app st head_args, true) rest_args
          in
          pp_cast table ~expected ~actual:(Some Tunknown) recv
  in
  function
    | MLrel n as a ->
        let id = get_db_name n env in
        apply_cast (type_of_expr tenv a) (pr_id id)
    | MLapp (f,args') ->
        let arg_tys = match type_of_expr tenv f with
          | Some ft -> arg_types ft (List.length args')
          | None -> List.map (fun _ -> None) args'
        in
        let stl =
          List.map2 (fun a ety -> pp_expr table env tenv ety [] a) args' arg_tys
        in
        pp_expr table env tenv expected (stl @ args) f
    | MLlam _ as a ->
        let fl,a' = collect_lams a in (* [fl] : arguments, [a'] : body *)
        (* [fl] lists binders innermost first; [peel_lams] returns argument
           types outermost first, hence the [List.rev] before pushing. An
           applied lambda (args <> []) is a redex whose type no longer
           matches [expected], so we give up on types there. *)
        let n = List.length fl in
        let param_tys, body_ty =
          match expected with
          | Some t when List.is_empty args -> peel_lams t n
          | _ -> List.init n (fun _ -> None), None
        in
        let fl,env' = push_vars (List.map id_of_mlid fl) env in
        let tenv' = List.rev param_tys @ tenv in
        apply (pp_abst (pp_expr table env' tenv' body_ty [] a') (List.rev fl))
    | MLletin (id,a1,a2) ->
        (* If [a1] is already an application of a fix (a computed value,
           not the bare recursive function) and the let-bound variable is
           used more than once below, this substitution duplicates the
           recursive computation itself — it will be re-executed once per
           use, not just re-printed as source text. *)
        if is_fix_head a1 then pp_expr table env tenv expected args (ast_subst a1 a2)
        else
          let body_expected = if List.is_empty args then expected else None in
          let a1_ty = type_of_expr tenv a1 in
          let i,env' = push_vars [id_of_mlid id] env in
          let pp_id = pr_id (List.hd i)
          and pp_a1 = pp_expr table env tenv None [] a1
          and pp_a2 = pp_expr table env' (a1_ty :: tenv) body_expected [] a2 in
          hv 0 (apply (pp_letin pp_id pp_a1 pp_a2))
    | MLglob r ->
        apply_cast (lookup_const_type r) (pp_global table Term r)
    | MLcons (typ,r,args') -> (* [r] : a name of a constructor *)
        assert (List.is_empty args);
        let arg_tys = match constructor_arg_types r, typ with
          | Some tys, Tglob (_, targs) when Int.equal (List.length tys) (List.length args') ->
              List.map (fun ty -> Some (type_subst_list targs ty)) tys
          | _ -> List.map (fun _ -> None) args'
        in
        let cons = str "new " ++ pp_global table Cons r ++
          paren (prlist_with_sep comma
                   (fun (a, ety) -> pp_expr table env tenv ety [] a)
                   (List.combine args' arg_tys)) in
        let ind = get_ind r in
        let cons =
          if is_custom ind || is_inline_custom ind then cons
          else paren (paren (pp_global table Type ind) ++ spc () ++ cons)
        in
        pp_cast table ~expected ~actual:(Some typ) cons
    | MLtuple _ -> user_err Pp.(str "Cannot handle tuples in Java yet.")
    | MLcase (typ,t, pv) ->
        (* No cast around the conditional chain: each branch body receives
           the expected type and conforms on its own. *)
        let branch_expected = if List.is_empty args then expected else None in
        apply (paren (pp_pat table env tenv typ branch_expected t pv))
    | MLfix (i,ids,defs) ->
        (* No cast: [fixK] is a generic method, target-typed by context. *)
        let ids',env' = push_vars (List.rev (Array.to_list ids)) env in
        let tenv' = List.map (fun _ -> None) (Array.to_list ids) @ tenv in
        pp_fix table env' tenv' i (Array.of_list (List.rev ids'),defs) args
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
        (* [a]'s ML type disagrees with the context by construction, so the
           inner printer's own actual type triggers the cast to [expected]
           where one is needed. *)
        pp_expr table env tenv expected args a
    | MLaxiom s ->
        str "error" ++ paren (pp_java_string ("AXIOM TO BE REALIZED (" ^ s ^ ")"))
    | MLuint _ -> user_err Pp.(str "Cannot handle primitive integers in Java yet.")
    | MLfloat _ -> user_err Pp.(str "Cannot handle primitive floats in Java yet.")
    | MLstring _ -> user_err Pp.(str "Cannot handle primitive strings in Java yet.")
    | MLparray _ -> user_err Pp.(str "Cannot handle persistent arrays in Java yet.")

and pp_fix table env tenv i (ids,bl) args =
  if not (Int.equal (Array.length ids) 1 && Int.equal (Array.length bl) 1
          && Int.equal i 0)
  then user_err Pp.(str "Cannot handle mutually recursive definitions in Java yet.");
  let k = List.length args in
  record_fix_arity k;
  str "fix" ++ int k ++
    paren
      (pr_id ids.(0) ++ str " -> " ++ pp_expr table env tenv None [] bl.(0) ++
       (match args with
        | [] -> mt ()
        | _ -> str ", " ++ prlist_with_sep comma identity args))

and pp_one_pat table env tenv typ expected exp (ids,p,t) =
  (* push_vars after List.rev_map makes the head of ids' correspond to
     de Bruijn 1 (= the last constructor argument). To match constructor
     field index j (0 = first argument) we use List.rev ids'. *)
  let n = List.length ids in
  let ids', env' = push_vars (List.rev_map id_of_mlid ids) env in
  let ids_field = List.rev ids' in
  let constr = pp_gen_pat table p in
  (* Declared field types (over the inductive's type variables — the static
     Java type of the field access) and their instantiation at the
     scrutinee's type arguments. Casting the field access in the [let]
     binding also types the bound variable, via [let]'s inference. *)
  let sig_tys = match p with
    | Pusual r ->
        (match constructor_arg_types r with
         | Some tys when Int.equal (List.length tys) n -> Some tys
         | _ -> None)
    | _ -> None
  in
  let inst_tys = match sig_tys, typ with
    | Some tys, Tglob (_, targs) -> Some (List.map (type_subst_list targs) tys)
    | _ -> None
  in
  let field_ty j = match inst_tys with
    | Some tys -> Some (List.nth tys j)
    | None -> None
  in
  let tenv' = List.rev (List.init n field_ty) @ tenv in
  let body = pp_expr table env' tenv' expected [] t in
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
        let declared = match sig_tys with
          | Some tys -> Some (List.nth tys j)
          | None -> None
        in
        let access =
          pp_cast table ~expected:(field_ty j) ~actual:declared
            (cast_exp ++ str "." ++ field)
        in
        pp_letin var access acc)
    (List.init n (fun j -> j))
    body
  in
  str constr, wrapped

(* A top-level [Pwild] or [Prel] matches unconditionally, so it cannot (and
   need not) be tested with [instanceof]: its body is the default of the
   conditional chain. [Prel] additionally binds the scrutinee to a variable. *)
and pp_catch_all_pat table env tenv typ expected scrut (ids,p,t) =
  match p with
  | Pwild ->
      assert (List.is_empty ids);
      pp_expr table env tenv expected [] t
  | Prel _ ->
      let ids', env' = push_vars (List.rev_map id_of_mlid ids) env in
      let body = pp_expr table env' (Some typ :: tenv) expected [] t in
      (match ids' with
       | [id] -> pp_letin (pr_id id) scrut body
       | _ -> assert false)
  | _ -> assert false

and pp_pat table env tenv typ expected t pv =
  let exp = pp_expr table env tenv None [] t in
  match t with
  | MLrel _ | MLglob _ ->
      (* already a simple value: safe and cheap to repeat in place *)
      pp_pat_branches table env tenv typ expected exp pv
  | _ ->
      (* bind the scrutinee once so a complex/effectful expression is not
         re-evaluated in every [instanceof] test and field access. The name is
         reserved in the avoid-set only (not the de Bruijn list) so the branch
         bodies keep their original de Bruijn indices. *)
      let db, avoid = env in
      let scrut_id = rename_id (Id.of_string "scrutinee") avoid in
      let env = (db, Id.Set.add scrut_id avoid) in
      let scrut = pr_id scrut_id in
      pp_letin scrut exp (pp_pat_branches table env tenv typ expected scrut pv)

(* Every constructor branch (including the last one) is guarded by an
   [instanceof] test; the chain ends with the first catch-all branch if any,
   otherwise with an explicit match-failure so that a value fitting no branch
   raises a clear error instead of an accidental ClassCastException. *)
and pp_pat_branches table env tenv typ expected scrut pv =
  let is_catch_all (_,p,_) = match p with Pwild | Prel _ -> true | _ -> false in
  let rec split acc = function
    | [] -> List.rev acc, None
    | b :: _ when is_catch_all b -> List.rev acc, Some b (* later branches are unreachable *)
    | b :: rest -> split (b :: acc) rest
  in
  let tests, default = split [] (Array.to_list pv) in
  let pp_default = match default with
    | Some b -> pp_catch_all_pat table env tenv typ expected scrut b
    | None -> str "error(\"non-exhaustive match\")"
  in
  prlist_strict
    (fun b ->
      let constr, body = pp_one_pat table env tenv typ expected scrut b in
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

let pp_one_field table r i = function
  | Some r' -> pp_global_with_key table Term (kn_of_ind (get_ind r)) r'
  | None -> pp_global table Type (get_ind r) ++ str "__" ++ int i

let pp_fields table r fields = List.map_i (pp_one_field table r) 0 fields

let pp_equiv table name inst = function
  | NoEquiv, _ -> mt ()
  | Equiv kn, i ->
    let r = { glob = GlobRef.IndRef (MutInd.make1 kn, i); inst } in
    str " = " ++ pp_global table Type r
  | RenEquiv ren, _  ->
      str " = " ++ str (ren^".") ++ name

let pp_instance_var t name = str "final " ++ t ++ str " " ++ name ++ str ";" ++ fnl()
let pp_java_constructor classname ty_name_list = 
  hv 2 (classname ++ paren (prlist_with_sep (fun () -> str ", ") (fun (t, name) -> t ++ str " " ++ name) ty_name_list) ++ str " {" ++ fnl() ++
      prlist_strict (fun (_, name) -> str "this." ++ name ++ str " = " ++ name ++ str ";" ++ fnl()) ty_name_list)
    ++ str "}" ++ fnl()


(* class with one constructor *)
let pp_singleton table packet =
  let name = pp_global_name table Type packet.ip_typename_ref in
  let fieldname = Id.print packet.ip_consnames.(0) in
  let ty = pp_type table (List.hd packet.ip_types.(0)) in
  str "public static class " ++ name ++ str " {" ++ fnl() ++
    pp_instance_var ty fieldname ++ fnl() ++
    pp_java_constructor name [(ty, fieldname)] ++ fnl()
    ++ str "}" ++ fnl2()

(* class with two or more constructors *)
let pp_record table fields ip_equiv packet =
  let ind = packet.ip_typename_ref in
  let name = pp_global_name table Type ind in
  let fieldnames = pp_fields table ind fields in
  let l = List.combine fieldnames packet.ip_types.(0) in
  str "public static class " ++ name ++ str " {" ++ fnl() ++
    prlist_strict (fun (p,t) -> pp_instance_var (pp_type table t) p) l ++ fnl() ++
    (* pp_equiv table name ind.inst ip_equiv ++ *)
    pp_java_constructor name (List.map (fun (p, t) -> (pp_type table t, p)) l) ++ fnl() ++
  str " } " ++ fnl2()

(* one [Inductive a := ... .] *)
let pp_one_ind table inst ip_equiv name cnames ctyps =
  let pp_constructor i typs =
    hv 2 (str "public static class " ++ cnames.(i) ++ str " implements " ++ name ++ str " {" ++ fnl() ++
    (* "value" is dummy, must be changed *)
      prlist_strict identity (List.mapi (fun j t -> pp_instance_var (pp_type table t) (cnames.(i) ++ str (string_of_int j))) typs)
        ++ fnl() ++
        hv 2 (pp_java_constructor cnames.(i) (List.mapi (fun j t -> (pp_type table t, cnames.(i) ++ str (string_of_int j))) typs)) ++ fnl() ++
    str "}") ++ fnl2()
  in
  name ++
  pp_equiv table name inst ip_equiv ++ str " {}" ++ fnl()
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
        pp_one_ind table inst ip_equiv names.(i) cnames.(i) p.ip_types ++
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
  | Dind i ->
      let i = expand_ind_aliases i in
      record_ind i; pp_mind table i
  | Dtype (r, _, t) ->
      if is_custom r then
        user_err Pp.(str "Cannot handle custom extraction of types in Java yet.")
      else
        let body = match t with
          (* An unrealized axiom type ([Axiom t : Type]) has no body; its
             values are treated as [Object], consistently with term-level
             axioms. A raw [Taxiom] must not be recorded: [pp_type] asserts
             on it. *)
          | Taxiom -> Tunknown
          | t -> expand_aliases t
        in
        record_type_alias r body;
        mt ()
  | Dfix (rv, defs, ty) ->
    (* Declare fields first, then assign in an instance initializer block.
       This avoids the "self-reference in initializer" error that occurs when a
       recursive lambda field initializer refers to the field being initialized. *)
    let n = Array.length rv in
    let ty = Array.map expand_aliases ty in
    (* Recorded before printing so that recursive references inside the
       bodies already find their own types. *)
    let () = Array.iteri (fun i r -> record_const_type r ty.(i)) rv in
    let decl i =
      if is_inline_custom rv.(i) then mt ()
      else str "static " ++ pp_type table ty.(i) ++ spc() ++ pp_global table Term rv.(i) ++ str ";" ++ fnl()
    in
    let init i =
      if is_inline_custom rv.(i) then mt ()
      else pp_global table Term rv.(i) ++ str " = " ++
        (if is_custom rv.(i) then str (find_custom rv.(i))
         else pp_expr table (empty_env table ()) [] (Some ty.(i)) [] defs.(i)) ++ str ";" ++ fnl()
    in
    Array.fold_left (++) (mt ()) (Array.init n decl) ++
    str "static {" ++ fnl() ++
    Array.fold_left (++) (mt ()) (Array.init n init) ++
    str "}" ++ fnl2()
  | Dterm (r, a, t) ->
      let t = expand_aliases t in
      record_const_type r t;
      if is_inline_custom r then mt ()
      else
        hov 2 (str "static " ++ pp_type table t ++ spc() ++ pp_global table Term r ++ str " = " ++
                        (if is_custom r then str (find_custom r)
                         else pp_expr table (empty_env table ()) [] (Some t) [] a) ++ str ";")
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

let pp_struct table id =
  let pp_sel (mp,sel) = State.with_visibility table mp [] begin fun table ->
    prlist_strict (fun e -> pp_structure_elem table e) sel
  end in
  fun structure ->
    reset_fix_arities ();
    reset_type_info ();
    let body = prlist_strict pp_sel structure in
    let arities =
      if Int.Set.mem 0 !fix_arities then Int.Set.add 1 !fix_arities
      else !fix_arities
    in
    str "class " ++ str (java_class_name id) ++ str " {" ++ fnl() ++ fnl() ++
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
    Int.Set.fold (fun k pp -> pp ++ pp_fix_helper k) arities (mt ()) ++
    body ++
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
