(** Copyright 2024, Vlasenco Daniel and Kudrya Alexandr *)

(** SPDX-License-Identifier: MIT *)

open Ast
open Format
open Checks

let pprint_ident ident = asprintf "%s" ident
let pprint_sep_star = asprintf " * "
let pprint_sep_colon = asprintf "; "
let pprint_sep_nl = asprintf "\n\n"
let pprint_sep_comma = asprintf ", "
let pprint_sep_and = asprintf " and "
let pprint_sep_or = asprintf " | "

let pprint_sep_by print sep list =
  let rec helper acc = function
    | fst :: snd :: tl ->
      let acc = String.concat "" [ acc; print fst; sep ] in
      helper acc (snd :: tl)
    | fst :: _ -> acc ^ print fst
    | [] -> acc
  in
  helper "" list
;;

(* Not enough brackets, probably *)
let rec pprint_measure =
  let pr_m m =
    match m with
    | Measure_dimless | Measure_ident _ -> asprintf "%s" (pprint_measure m)
    | _ -> asprintf "(%s)" (pprint_measure m)
  in
  let pr_exp = asprintf "%d" in
  function
  | Measure_ident mid -> asprintf "%s" mid
  | Measure_prod (m1, m2) -> asprintf "%s * %s" (pr_m m1) (pr_m m2)
  | Measure_div (m1, m2) -> asprintf "%s / %s" (pr_m m1) (pr_m m2)
  | Measure_pow (m, exp) -> asprintf "%s ^ %s" (pr_m m) (pr_exp exp)
  | Measure_dimless -> asprintf "1"
;;

let pprint_uom = function
  | Unit_of_measure (n, m) ->
    (match n with
     | Mnum_float f -> asprintf "%F<%s>" f (pprint_measure m)
     | Mnum_int i -> asprintf "%d<%s>" i (pprint_measure m))
;;

(* "%f" prints exactly 6 digits after dot
   "%F" prints as much as needed *)
let pprint_const = function
  | Const_bool b -> asprintf "%b" b
  | Const_int i -> asprintf "%d" i
  | Const_char c -> asprintf "%C" c
  | Const_string s -> asprintf "%S" s
  | Const_float f -> asprintf "%F" f
  | Const_unit_of_measure u -> asprintf "%s" (pprint_uom u)
  | Const_unit -> asprintf "()"
;;

let rec pprint_type = function
  | Type_int -> asprintf "int"
  | Type_float -> asprintf "float"
  | Type_bool -> asprintf "bool"
  | Type_char -> asprintf "char"
  | Type_string -> asprintf "string"
  | Type_unit -> asprintf "unit"
  | Type_var t -> asprintf "'a%s" t
  | Type_option t ->
    let ttag =
      match t with
      | Type_int
      | Type_float
      | Type_bool
      | Type_char
      | Type_string
      | Type_unit
      | Type_option _
      | Type_list _
      | Type_var _ -> pprint_type t
      | _ -> String.concat "" [ "("; pprint_type t; ")" ]
    in
    asprintf "%s option" ttag
  | Type_list t ->
    let ttag =
      match t with
      | Type_int
      | Type_float
      | Type_bool
      | Type_char
      | Type_string
      | Type_unit
      | Type_option _
      | Type_list _
      | Type_var _ -> pprint_type t
      | _ -> String.concat "" [ "("; pprint_type t; ")" ]
    in
    asprintf "%s list" ttag
  | Type_func (arg, ret) ->
    (match arg with
     | Type_func _ -> asprintf "(%s) -> %s" (pprint_type arg) (pprint_type ret)
     | _ -> asprintf "%s -> %s" (pprint_type arg) (pprint_type ret))
  | Type_tuple (t1, t2, rest) ->
    let list = t1 :: t2 :: rest in
    asprintf "%s" (pprint_sep_by pprint_type pprint_sep_star list)
;;

let rec pprint_pat = function
  | Pattern_ident_or_op p -> asprintf "%s" (pprint_ident p)
  | Pattern_const p -> asprintf "%s" (pprint_const p)
  | Pattern_wild -> asprintf "_"
  | Pattern_typed (p, t) -> asprintf "(%s : %s)" (pprint_pat p) (pprint_type t)
  | Pattern_tuple (p1, p2, rest) ->
    let list = p1 :: p2 :: rest in
    asprintf "(%s)" (pprint_sep_by pprint_pat pprint_sep_comma list)
  | Pattern_list list -> asprintf "[%s]" (pprint_sep_by pprint_pat pprint_sep_colon list)
  | Pattern_or (p1, p2) -> asprintf "%s | %s" (pprint_pat p1) (pprint_pat p2)
  | Pattern_cons (p1, p2) -> asprintf "%s :: %s" (pprint_pat p1) (pprint_pat p2)
  | Pattern_option opt ->
    (match opt with
     | None -> asprintf "None"
     | Some x ->
       (match x with
        | Pattern_list _ | Pattern_or _ | Pattern_option (Some _) ->
          asprintf "Some (%s)" (pprint_pat x)
        | _ -> asprintf "Some %s" (pprint_pat x)))
;;

(* Prints let f x = y in e as let f = fun x -> y in e *)
let rec pprint_binds list =
  let pprint_bind (Bind (p, e)) = asprintf "%s = %s" (pprint_pat p) (pprint_expr e) in
  pprint_sep_by pprint_bind pprint_sep_and list

and pprint_rules list =
  let pprint_rule (Rule (p, e)) = asprintf "%s -> %s" (pprint_pat p) (pprint_expr e) in
  pprint_sep_by pprint_rule pprint_sep_or list

and pprint_expr =
  let pprint_expr_paren e =
    match e with
    | Expr_lam _
    | Expr_let _
    | Expr_ifthenelse _
    | Expr_match _
    | Expr_function _
    | Expr_apply _ -> asprintf "(%s)" (pprint_expr e)
    | Expr_const (Const_int i) when i < 0 -> asprintf "(%d)" i
    | Expr_const (Const_float f) when f < 0. -> asprintf "(%F)" f
    | _ -> asprintf "%s" (pprint_expr e)
  in
  function
  | Expr_const e -> asprintf "%s" (pprint_const e)
  | Expr_ident_or_op e -> asprintf "%s" (pprint_ident e)
  | Expr_typed (e, t) -> asprintf "(%s : %s)" (pprint_expr e) (pprint_type t)
  | Expr_tuple (e1, e2, rest) ->
    let list = e1 :: e2 :: rest in
    asprintf "(%s)" (pprint_sep_by pprint_expr pprint_sep_comma list)
  | Expr_list list -> asprintf "[%s]" (pprint_sep_by pprint_expr pprint_sep_colon list)
  | Expr_lam (p, e) -> asprintf "fun %s -> %s" (pprint_pat p) (pprint_expr e)
  | Expr_let (flag, b1, rest, e) ->
    let flag = if flag = Recursive then " rec " else " " in
    let list = b1 :: rest in
    asprintf "let%s%s in %s" flag (pprint_binds list) (pprint_expr e)
  | Expr_ifthenelse (i, t, e) ->
    (match e with
     | Some e ->
       asprintf "if %s then %s else %s" (pprint_expr i) (pprint_expr t) (pprint_expr e)
     | None -> asprintf "if %s then %s" (pprint_expr i) (pprint_expr t))
  | Expr_apply (Expr_apply (Expr_ident_or_op op, e1), e2) when is_builtin_op op ->
    asprintf "%s %s %s" (pprint_expr_paren e1) op (pprint_expr_paren e2)
  | Expr_apply (e1, e2) -> asprintf "%s %s" (pprint_expr_paren e1) (pprint_expr_paren e2)
  | Expr_match (e, r1, rest) ->
    let list = r1 :: rest in
    asprintf "match %s with %s" (pprint_expr e) (pprint_rules list)
  | Expr_function (r1, rest) ->
    let list = r1 :: rest in
    asprintf "function %s" (pprint_rules list)
  | Expr_option opt ->
    (match opt with
     | None -> asprintf "None"
     | Some x -> asprintf "Some %s" (pprint_expr x))
;;

let pprint_struct_item = function
  | Str_item_eval e -> asprintf "%s" (pprint_expr e)
  | Str_item_def (flag, b1, rest) ->
    let flag = if flag = Recursive then " rec " else " " in
    let list = b1 :: rest in
    asprintf "let%s%s" flag (pprint_binds list)
  | Str_item_type_def td ->
    (match td with
     | Measure_type_def (m1, m2) ->
       (match m2 with
        | None -> asprintf "[<Measure>] type %s" m1
        | Some m2' -> asprintf "[<Measure>] type %s = %s" m1 (pprint_measure m2')))
;;

let pprint_program list =
  asprintf "%s\n" (pprint_sep_by pprint_struct_item pprint_sep_nl list)
;;
