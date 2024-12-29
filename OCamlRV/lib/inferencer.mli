(** Copyright 2024-2025, Viacheslav Sidorov and Danila Rudnev-Stepanyan *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

val run_infer
  :  Ast.structure
  -> ( (string, InferencerCore.Scheme.t, Base.String.comparator_witness) Base.Map.t
       , InferencerCore.error )
       result