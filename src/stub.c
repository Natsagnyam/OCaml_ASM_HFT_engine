#define _GNU_SOURCE
#include <stdint.h>
#include <x86intrin.h>
#include <sched.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/bigarray.h>
#include <caml/fail.h>
#include <string.h>  


// Declare the assembly function so C knows its signature
extern void asm_push_blind(uint64_t *buffer, uint64_t *tail, int64_t value);

static uint64_t *global_tail = NULL;
static uint64_t *global_buffer = NULL;

CAMLprim value stub_set_pointers(value buffer, value tail) {
    global_buffer = (uint64_t*)Caml_ba_data_val(buffer);
    global_tail = (uint64_t*)Caml_ba_data_val(tail);
    return Val_unit;
}

CAMLprim value stub_push_blind(value val) {
    asm_push_blind(global_buffer, global_tail, Long_val(val));
    return Val_unit;
}

CAMLprim value stub_get_ticks(value unit) {
    return caml_copy_int64(__rdtsc());
}



CAMLprim value stub_alloc_aligned(value size) {
    void *ptr;
    size_t s = Long_val(size);
    if (posix_memalign(&ptr, 64, s) != 0) caml_failwith("alloc failed");
    
    // Explicitly zero the allocated block
    memset(ptr, 0, s); 
    
    // Return the Bigarray wrapper
    return caml_ba_alloc_dims(CAML_BA_INT64 | CAML_BA_C_LAYOUT, 1, ptr, s / 8);
}


CAMLprim value caml_init_engine(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_unit);
}

CAMLprim value stub_pin_thread(value core_id) {
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    CPU_SET(Int_val(core_id), &cpuset);
    sched_setaffinity(0, sizeof(cpu_set_t), &cpuset);
    return Val_unit;
}

CAMLprim value stub_alloc_ring_buffer(value size) {
    CAMLparam1(size);
    size_t s = Long_val(size);
    void *ptr = mmap(NULL, s, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (ptr == MAP_FAILED) caml_failwith("mmap failed");
    madvise(ptr, s, MADV_HUGEPAGE);
    CAMLreturn(caml_ba_alloc_dims(CAML_BA_INT64 | CAML_BA_C_LAYOUT, 1, ptr, s / 8));
}

CAMLprim value stub_wait_for_data(value unit) {
    __builtin_ia32_pause();
    return Val_unit;
}

CAMLprim value stub_get_data_ptr(value ba) {
    void* ptr = Caml_ba_data_val(ba);
    // Print the address for GDB debugging
    printf("DEBUG: Returning raw pointer: %p\n", ptr); 
    return caml_copy_int64((int64_t)ptr);
}




