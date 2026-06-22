open Bigarray

external alloc_aligned : int -> (int64, int64_elt, c_layout) Array1.t = "stub_alloc_aligned"
external pin_thread : int -> unit = "stub_pin_thread"
external asm_pop : (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> int = "stub_asm_pop"
external asm_push : (int64, int64_elt, c_layout) Array1.t -> (int64, int64_elt, c_layout) Array1.t -> int -> unit = "stub_asm_push"
external run_benchmark : int -> unit = "stub_run_latency_benchmark"

let buffer = alloc_aligned (65536 * 8)
let tail   = alloc_aligned 64
let head   = alloc_aligned 64

let () =
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
        if res != -1 then begin
          if i mod 100 = 0 then Printf.printf "Consumed: %d\n" res;
          loop (i + 1)
        end else begin
          Thread.yield ();
          loop i
        end
      end
    in loop 0) ()
  in
  Thread.join producer;
  Thread.join consumer;
  print_endline "Test complete."