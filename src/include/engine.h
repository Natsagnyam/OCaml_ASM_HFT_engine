#ifndef ENGINE_H
#define ENGINE_H

#include <stdint.h>

// Ensure these are padded to 64 bytes in OCaml/C memory allocation
typedef struct {
    uint64_t pad1[7]; 
    volatile uint64_t head;
    uint64_t pad2[7];
} consumer_ctrl;

typedef struct {
    uint64_t pad1[7];
    volatile uint64_t tail;
    uint64_t pad2[7];
} producer_ctrl;

#endif