open Bigarray

(* --- FFI Declarations --- *)
external init_engine : unit -> unit = "caml_init_engine"
external pin_thread : int -> unit = "stub_pin_thread"
external alloc_aligned : int -> (int64, int64_elt, c_layout) Array1.t = "stub_alloc_aligned"
external stub_wait_for_data : unit -> unit = "stub_wait_for_data"

(* ASM Bridges *)
external asm_push : (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> int -> unit = "stub_asm_push"
external asm_pop : (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> int = "stub_asm_pop"
external run_benchmark : int -> unit = "stub_run_latency_benchmark"
external stub_log_push : int -> unit = "stub_log_push"

(* --- Memory Allocation (Using Custom Aligned Allocator) --- *)
let buffer = alloc_aligned (65536 * 8)
let tail   = alloc_aligned 64
let head   = alloc_aligned 64
(* Add this line to allocate memory for the logging ring buffer *)
let log_buffer = alloc_aligned (65536 * 8)



(* Update your logger thread to use the new buffer *)
let _ = Thread.create (fun () ->
  pin_thread 3;
  while true do
    (* Pass log_buffer here *)
    let res = asm_pop log_buffer head tail in
    if res <> -1 then
      Printf.printf "Log: %d\n" res
    else
      stub_wait_for_data ()
  done
) ()

(* Inside your Hot Path *)
let rec run_engine () =
  asm_push buffer tail 123;
  let result = asm_pop buffer head tail in
  
  if result <> -1 then
    (* NON-BLOCKING: Just push the log to the buffer *)
    stub_log_push result;
    
  stub_wait_for_data ();
  run_engine ()



(* --- Entry Point --- *)
let () =
  print_endline "Initializing Natska Engine...";
  init_engine ();
  pin_thread 2; 
  
  print_endline "Aligned memory mapped.";
  run_benchmark 10000;

  print_endline "Starting threaded test...";
  let producer = Thread.create (fun () ->
    pin_thread 0;
    for i = 0 to 1000 do
      asm_push buffer tail i
    done) ()
  in
  let consumer = Thread.create (fun () ->
    pin_thread 1;
    let rec loop i =
      if i <= 1000 then begin
        let res = asm_pop buffer head tail in
        if res <> -1 then begin
          if i mod 100 = 0 then Printf.printf "Consumed: %d\n" res;
          loop (i + 1)
        end else begin
          stub_wait_for_data ();
          loop i
        end
      end
    in loop 0) ()
  in
  Thread.join producer;
  Thread.join consumer;
  print_endline "Test complete.";
  
  print_endline "Engine Initialized. Starting loop.";
  run_engine ()

  






