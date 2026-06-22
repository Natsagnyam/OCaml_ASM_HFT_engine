// stub.c
#define _GNU_SOURCE
#include <pthread.h>
#include <sched.h>
#include <caml/mlvalues.h>
#include <caml/bigarray.h>
#include <caml/memory.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include "ring_buffer.h"

// Globals
uint32_t buffer[BUFFER_SIZE];
producer_ctrl the_producer __attribute__((aligned(64))) = {0};
consumer_ctrl the_consumer __attribute__((aligned(64))) = {0};

// Comparison function for qsort (Standard C)
int compare_uint64(const void *a, const void *b) {
    uint64_t arg1 = *(const uint64_t*)a;
    uint64_t arg2 = *(const uint64_t*)b;
    if (arg1 < arg2) return -1;
    if (arg1 > arg2) return 1;
    return 0;
}

static inline uint64_t get_cycles(void) {
    uint32_t low, high;
    __asm__ volatile ("lfence; rdtsc" : "=a" (low), "=d" (high));
    return ((uint64_t)high << 32) | low;
}

CAMLprim value stub_run_latency_benchmark(value v_iterations) {
    CAMLparam1(v_iterations);
    int iterations = Int_val(v_iterations);
    uint64_t *samples = (uint64_t*)malloc(iterations * sizeof(uint64_t));

    for (int i = 0; i < iterations; i++) {
        uint64_t start = get_cycles();
        
        buffer[the_producer.tail.fast_local_ptr & MASK] = (uint32_t)i;
        __asm__ volatile ("sfence" ::: "memory");
        the_producer.tail.fast_local_ptr += 1;

        while (the_consumer.head.fast_local_ptr == the_producer.tail.fast_local_ptr) {
            __asm__ volatile ("pause");
        }
        
        uint64_t end = get_cycles();
        the_consumer.head.fast_local_ptr += 1;
        
        samples[i] = (i > 100) ? (end - start) : 0;
    }

    // Sort only the valid samples (starting from index 100)
    qsort(samples + 100, iterations - 100, sizeof(uint64_t), compare_uint64);

    uint64_t p99 = samples[100 + (int)((iterations - 100) * 0.99)];
    double freq_ghz = 3.59885; 
    
    printf("P99 Latency: %lu cycles (%.2f nsec)\n", p99, (double)p99 / freq_ghz);

    free(samples);
    CAMLreturn(Val_unit);
}

// 3. OCAML STUBS
CAMLprim value stub_pin_thread(value v_cpu_id) {
    CAMLparam1(v_cpu_id);
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    CPU_SET(Int_val(v_cpu_id), &cpuset);
    pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpuset);
    CAMLreturn(Val_unit);
}

CAMLprim value stub_asm_push(value v_buffer, value v_tail, value v_val) {
    CAMLparam3(v_buffer, v_tail, v_val);
    extern void asm_push(void* buffer, void* tail, uint64_t value);
    asm_push(Caml_ba_data_val(v_buffer), Caml_ba_data_val(v_tail), (uint64_t)Long_val(v_val));
    CAMLreturn(Val_unit);
}

CAMLprim value stub_asm_pop(value v_buffer, value v_head, value v_tail) {
    CAMLparam3(v_buffer, v_head, v_tail);
    extern uint64_t asm_pop(void* buffer, void* head, void* tail);
    uint64_t res = asm_pop(Caml_ba_data_val(v_buffer), Caml_ba_data_val(v_head), Caml_ba_data_val(v_tail));
    CAMLreturn(Val_long((long)res));
}

CAMLprim value stub_alloc_aligned(value v_size) {
    void* ptr = NULL;
    posix_memalign(&ptr, 64, (size_t)Long_val(v_size));
    return caml_ba_alloc_dims(CAML_BA_INT64 | CAML_BA_C_LAYOUT, 1, ptr, Long_val(v_size) / 8);
}