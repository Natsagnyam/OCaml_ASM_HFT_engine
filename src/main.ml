open Bigarray


external alloc_aligned : int -> (int64, int64_elt, c_layout) Array1.t = "stub_alloc_aligned"
external pin_thread : int -> unit = "stub_pin_thread"
external asm_pop : (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> int = "stub_asm_pop"
external asm_push : (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> int -> unit = "stub_asm_push"

(* Move definitions to global scope so they are visible to Thread.create *)
let buffer = alloc_aligned (65536 * 8)
let tail   = alloc_aligned 64
let head   = alloc_aligned 64

let producer = Thread.create (fun () ->
  pin_thread 0;
  for i = 0 to 1000 do
    asm_push buffer tail i
  done) ()

let consumer = Thread.create (fun () ->
  pin_thread 1;
  for i = 0 to 1000 do
    let res = asm_pop buffer head tail in
    Printf.printf "Consumed: %d\n" res
  done) ()

let () =
  print_endline "Aligned memory mapped. Starting test...";
  Thread.join producer;
  Thread.join consumer;
  print_endline "Test complete."