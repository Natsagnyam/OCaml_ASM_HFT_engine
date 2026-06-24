open Bigarray

(* External bindings *)
external init_engine : unit -> unit = "caml_init_engine"
external pin_thread : int -> unit = "stub_pin_thread"
external stub_alloc_ring_buffer : int -> (int64, int64_elt, c_layout) Array1.t = "stub_alloc_ring_buffer"
external stub_alloc_aligned : int -> (int64, int64_elt, c_layout) Array1.t = "stub_alloc_aligned"
external stub_set_pointers : (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> unit = "stub_set_pointers"
external asm_push_blind_caller : int -> unit = "stub_push_blind"
external stub_get_ticks : unit -> int64 = "stub_get_ticks"

(* External binding *)
external stub_run_benchmark_native : int64 -> unit = "stub_run_benchmark_native"
(* Initialization logic *)
let ring_buffer = stub_alloc_ring_buffer (65536 * 8)
let tail = stub_alloc_aligned 64



(* Call this instead of the loop *)
let run_native_benchmark () =
  let t0 = stub_get_ticks () in
  stub_run_benchmark_native 1_000_000L;
  let t1 = stub_get_ticks () in
  
  let diff = Int64.sub t1 t0 in
  let total_cycles = Int64.to_float diff in
  let avg_cycles = total_cycles /. 1_000_000.0 in
  
  (* Using your calibrated frequency *)
  let ghz = 3.599 in 
  Printf.printf "Average: %.2f cycles (%.2f ns)\n" avg_cycles (avg_cycles /. ghz)



let calibrate () =
  let t0 = stub_get_ticks () in
  Unix.sleep 1;
  let t1 = stub_get_ticks () in
  (* Use Int64.sub for subtraction *)
  let diff = Int64.sub t1 t0 in
  (* Convert to float for the GHz division *)
  let freq_ghz = Int64.to_float diff /. 1_000_000_000.0 in
  Printf.printf "Calibrated Frequency: %.3f GHz\n" freq_ghz;
  freq_ghz

let run_p99_benchmark ghz =
  let samples = Array.make 1_000_000 0L in
  for i = 0 to 999_999 do
      let t0 = stub_get_ticks () in
      asm_push_blind_caller 123;
      let t1 = stub_get_ticks () in
      (* Use Int64.sub instead of '-' *)
      samples.(i) <- Int64.sub t1 t0
    done;
    
    
  Array.sort compare samples;
    let p99 = samples.(990_000) in
    
    (* Division using Int64.div *)
    let avg = Int64.div (Array.fold_left Int64.add 0L samples) 1_000_000L in
    
    (* The division here is float division (/.) so it works with floats *)
    let to_ns cycles ghz = Int64.to_float cycles /. ghz in
    
    Printf.printf "Average: %Ld cycles (%.2f ns)\n" avg (to_ns avg ghz);
    Printf.printf "P99: %Ld cycles (%.2f ns)\n" p99 (to_ns p99 ghz)
    

(* Main Entry Point *)
let () =
  tail.{0} <- 0L;
  stub_set_pointers ring_buffer tail;
  init_engine ();
  pin_thread 1;
  let ghz = calibrate () in
  run_p99_benchmark ghz;
  print_endline "Benchmark complete."