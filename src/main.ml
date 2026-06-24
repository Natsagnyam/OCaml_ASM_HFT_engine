open Bigarray
open Thread

(* --- FFI Declarations --- *)
external init_engine : unit -> unit = "caml_init_engine"
external pin_thread : int -> unit = "stub_pin_thread"
external alloc_aligned : int -> (int64, int64_elt, c_layout) Array1.t = "stub_alloc_aligned"
external stub_wait_for_data : unit -> unit = "stub_wait_for_data"
external asm_push : (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> int -> unit = "stub_asm_push"
external asm_pop : (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> int = "stub_asm_pop"
external stub_log_push : int -> unit = "stub_log_push"

(* --- Gate Controller for Sync Phase --- *)
type gate_t = { mutable producer_ready : int; mutable consumer_ready : int; mutable go_signal : int }
let gate = { producer_ready = 0; consumer_ready = 0; go_signal = 0 }

(* --- Memory Allocation --- *)
let buffer = alloc_aligned (65536 * 8)
let tail   = alloc_aligned 64
let head   = alloc_aligned 64

(* --- Execution Logic --- *)
(* --- Producer and Consumer definitions --- *)
let run_producer () =
  pin_thread 1; (* Producer pinned to Core 1 *)
  gate.producer_ready <- 1;
  while gate.go_signal = 0 do stub_wait_for_data () done;
  (* Hot path start *)
  for i = 0 to 1000000 do
    asm_push buffer tail i
  done

let run_consumer () =
  pin_thread 0; (* Consumer pinned to Core 0 *)
  gate.consumer_ready <- 1;
  while gate.go_signal = 0 do stub_wait_for_data () done;
  (* Hot path start *)
  for i = 0 to 1000000 do
    let res = asm_pop buffer head tail in
    if res = -1 then stub_wait_for_data ()
  done

let () =
  print_endline "Initializing Natska Engine...";
  init_engine ();
  
  let p = Thread.create run_producer () in
  let c = Thread.create run_consumer () in
  
  while gate.producer_ready = 0 || gate.consumer_ready = 0 do 
    stub_wait_for_data () 
  done;
  
  print_endline "Sync Phase Complete. Releasing Gates.";
  gate.go_signal <- 1;
  
  Thread.join p;
  Thread.join c;
  print_endline "Test complete."