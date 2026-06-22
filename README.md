# Natska Core: High-Performance SPSC Ring Buffer

A low-latency, lock-free Single-Producer Single-Consumer (SPSC) ring buffer implemented with an x86-64 assembly backend and OCaml FFI.

## Architecture
- **Zero-Copy FFI:** Bypasses OCaml boxing/tagging overhead for direct `int64_t` data transfer.
- **Cache-Line Isolated:** Uses 64-byte aligned padding to prevent false sharing between producer and consumer threads.
- **Memory Consistency:** Utilizes hardware `mfence` to guarantee data visibility between CPU cores without atomic contention.
- **Static Memory:** Pre-allocated aligned memory via `posix_memalign`.

## Build & Run
Prerequisites: `ocamlopt`, `gcc`, `as`.

```bash
make clean && make
./build/main.exe
gdb ./build/main.exe
