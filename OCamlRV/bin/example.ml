let rec list_iter l n =
  if n = 0
  then ()
  else (
    match l with
    | x :: xs ->
      let () = print_int x in
      list_iter xs (n - 1))
;;

list_iter [ 1; 2; 3; 4; 5 ] 5
let rec ones = 1 :: 2 :: 3 :: 4 :: ones;;

(* list_iter ones 10 *)
