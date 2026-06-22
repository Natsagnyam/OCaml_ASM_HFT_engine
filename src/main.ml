open Bigarray

external alloc_aligned : int -> (int64, int64_elt, c_layout) Array1.t = "stub_alloc_aligned"
external asm_pop : (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> int = "stub_asm_pop"
external asm_push : (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> int -> unit = "stub_asm_push"

let () =
  let buffer = alloc_aligned (65536 * 8) in
  let tail   = alloc_aligned 64 in
  let head   = alloc_aligned 64 in
  
  print_endline "Aligned memory mapped. Starting test...";

for i = 0 to 1000 do
    asm_push buffer tail i;
    let val_pop = asm_pop buffer head tail in
    (* Since val_pop is now a plain OCaml int, we print it directly *)
    Printf.printf "Pushed/Popped: %d\n" val_pop
  done;

  print_endline "Test complete."