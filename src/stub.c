#define _GNU_SOURCE
#include <pthread.h>
#include <sched.h>
#include <sys/mman.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <caml/mlvalues.h>
#include <caml/bigarray.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include "ring_buffer.h"

// --- GLOBALS ---
__attribute__((aligned(64))) producer_ctrl the_producer = {0};
__attribute__((aligned(64))) consumer_ctrl the_consumer = {0};
uint32_t *buffer = NULL;
// Define the logging buffer globally
uint32_t *log_buffer = NULL;

// --- ASSEMBLY ENGINE ---
extern void asm_push(void* buf, void* tail, uint64_t val);
extern uint64_t asm_pop(void* buf, void* head, void* tail);

// Inside stub.c, add these global instances
__attribute__((aligned(64))) producer_ctrl log_producer = {0};
__attribute__((aligned(64))) consumer_ctrl log_consumer = {0};

// Add a helper for the logger thread
CAMLprim value stub_log_push(value v_val) {
    CAMLparam1(v_val);
    // Ensure log_buffer is initialized (you may need a log_init_engine function 
    // or just use your existing init_engine to mmap it as well)
    extern void asm_push(void* buf, void* tail, uint64_t val);
    
    // Safety check
    if (log_buffer == NULL) CAMLreturn(Val_unit);

    asm_push(log_buffer, &log_producer.tail, (uint64_t)Long_val(v_val));
    CAMLreturn(Val_unit);
}

// --- FFI IMPLEMENTATIONS ---

CAMLprim value caml_init_engine(value unit) {
    CAMLparam1(unit);
    buffer = (uint32_t*)mmap(NULL, 2 * 1024 * 1024, PROT_READ | PROT_WRITE, 
                            MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB, -1, 0);
    if (buffer == MAP_FAILED) caml_failwith("mmap failed");
    CAMLreturn(Val_unit);
}

CAMLprim value stub_asm_push(value v_buffer, value v_tail, value v_val) {
    CAMLparam3(v_buffer, v_tail, v_val);
    asm_push(Caml_ba_data_val(v_buffer), Caml_ba_data_val(v_tail), (uint64_t)Long_val(v_val));
    CAMLreturn(Val_unit);
}

CAMLprim value stub_asm_pop(value v_buffer, value v_head, value v_tail) {
    CAMLparam3(v_buffer, v_head, v_tail);
    uint64_t res = asm_pop(Caml_ba_data_val(v_buffer), Caml_ba_data_val(v_head), Caml_ba_data_val(v_tail));
    CAMLreturn(Val_long((long)res));
}

CAMLprim value stub_wait_for_data(value unit) {
    CAMLparam0();
    __asm__ volatile ("pause");
    CAMLreturn(Val_unit);
}

CAMLprim value stub_run_latency_benchmark(value v_iterations) {
    CAMLparam1(v_iterations);
    int iterations = Int_val(v_iterations);
    uint64_t *samples = (uint64_t*)malloc(iterations * sizeof(uint64_t));
    
    // Minimal loop for accurate cycles
    for (int i = 0; i < iterations; i++) {
        uint64_t start;
        uint32_t low, high;
        __asm__ volatile ("lfence; rdtsc" : "=a" (low), "=d" (high));
        start = ((uint64_t)high << 32) | low;
        
        asm_push(buffer, &the_producer.tail, (uint64_t)i);
        asm_pop(buffer, &the_consumer.head, &the_producer.tail);
        
        __asm__ volatile ("lfence; rdtsc" : "=a" (low), "=d" (high));
        samples[i] = (((uint64_t)high << 32) | low) - start;
    }

    printf("P99 Latency: %lu cycles (%.2f nsec)\n", 
           samples[(int)(iterations * 0.99)], 
           (double)samples[(int)(iterations * 0.99)] / 3.6);
    
    free(samples);
    CAMLreturn(Val_unit);
}

CAMLprim value stub_pin_thread(value v_cpu_id) {
    CAMLparam1(v_cpu_id);
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    CPU_SET(Int_val(v_cpu_id), &cpuset);
    pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpuset);
    CAMLreturn(Val_unit);
}

CAMLprim value stub_alloc_aligned(value v_size) {
    void* ptr = NULL;
    if (posix_memalign(&ptr, 64, (size_t)Long_val(v_size)) != 0) caml_failwith("memalign failed");
    return caml_ba_alloc_dims(CAML_BA_INT64 | CAML_BA_C_LAYOUT, 1, ptr, Long_val(v_size) / 8);
}