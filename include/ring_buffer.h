#ifndef RING_BUFFER_H
#define RING_BUFFER_H

#include <stdint.h>
#include <stdatomic.h>

#define N 16
#define BUFFER_SIZE (1 << N)
#define MASK (BUFFER_SIZE - 1)

// The dual_passport union
typedef union {
    volatile uint32_t fast_local_ptr;
    _Atomic volatile uint32_t atomic_ptr;
} dual_passport;

// Producer structure
typedef struct __attribute__((aligned(64))) {
    uint8_t pad1[128];
    dual_passport tail;
    uint8_t pad2[124];
} producer_ctrl;

// Consumer structure
typedef struct __attribute__((aligned(64))) {
    uint8_t pad1[128];
    dual_passport head;
    uint8_t pad2[124];
} consumer_ctrl;

// Shared buffer
//extern uint32_t buffer[BUFFER_SIZE];
extern uint32_t *buffer;
#endif