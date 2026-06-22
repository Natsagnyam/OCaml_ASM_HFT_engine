#define _GNU_SOURCE
#include <pthread.h>
#include <sched.h>
#include <caml/mlvalues.h>
#include <caml/bigarray.h>
#include <caml/memory.h> // <--- ADD THIS LINE
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>


// External assembly functions
extern void asm_push(void* buffer, void* tail, uint64_t value);
extern uint64_t asm_pop(void* buffer, void* head, void* tail);


CAMLprim value stub_pin_thread(value v_cpu_id) {
    CAMLparam1(v_cpu_id);
    int cpu = Int_val(v_cpu_id);
    
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    CPU_SET(cpu, &cpuset);
    
    pthread_t current_thread = pthread_self();
    pthread_setaffinity_np(current_thread, sizeof(cpu_set_t), &cpuset);
    
    CAMLreturn(Val_unit);
}


// Push a value onto the ring buffer
CAMLprim value stub_asm_push(value v_buffer, value v_tail, value v_val) {
    CAMLparam3(v_buffer, v_tail, v_val);
    void* buffer = Caml_ba_data_val(v_buffer);
    void* tail = Caml_ba_data_val(v_tail);
    
    // Use Long_val to get the raw integer directly from the tagged 'int'
    int64_t val = (int64_t)Long_val(v_val); 
    
    asm_push(buffer, tail, (uint64_t)val);
    CAMLreturn(Val_unit);
}


// Pop a value from the ring buffer
CAMLprim value stub_asm_pop(value v_buffer, value v_head, value v_tail) {
    CAMLparam3(v_buffer, v_head, v_tail);
    
    void* buffer = Caml_ba_data_val(v_buffer);
    void* head = Caml_ba_data_val(v_head);
    void* tail = Caml_ba_data_val(v_tail);
    
    uint64_t res = asm_pop(buffer, head, tail);
    
    // Return the result tagged as an OCaml integer
    CAMLreturn(Val_long((long)res));
}

// Allocate 64-byte aligned memory for the buffer
CAMLprim value stub_alloc_aligned(value v_size) {
    size_t size = (size_t)Long_val(v_size);
    void* ptr = NULL;
    
    if (posix_memalign(&ptr, 64, size) != 0) {
        return Val_int(0);
    }
    
    // Wrap the aligned pointer in a Bigarray (Int64, C-layout)
    return caml_ba_alloc_dims(CAML_BA_INT64 | CAML_BA_C_LAYOUT, 1, ptr, size / 8);
}